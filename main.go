package main

import (
	"fmt"
	"github.build.ge.com/unshut/goboot/web"
	"github.build.ge.com/unshut/goboot/web/gorilla"
	"github.com/gorilla/mux"
	"github.com/kr/pty"
	"net/http"
	"os"
	"os/exec"
	"io"
	"golang.org/x/net/websocket"
)

const files string = "static/"

func sh(w http.ResponseWriter, r *http.Request) {
	wsHandler := func(ws *websocket.Conn) {
		// wrap the websocket into UTF-8 wrappers:
		wrapper := NewWebSockWrapper(ws, WebSocketTextMode)
		stdout := wrapper
		stderr := wrapper

		// this one is optional (solves some weird issues with vim running under shell)
		stdin := &InputWrapper{ws}

		// starts new command in a newly allocated terminal:
		// TODO: replace /bin/bash with:
		//		 kubectl exec -ti <pod> --container <container name> -- /bin/bash
		cmd := exec.Command("/bin/bash")
		tty, err := pty.Start(cmd)
		if err != nil {
			panic(err)
		}
		defer tty.Close()

		// pipe to/fro websocket to the TTY:
		go func() {
			io.Copy(stdout, tty)
		}()
		go func() {
			io.Copy(stderr, tty)
		}()
		go func() {
			io.Copy(tty, stdin)
		}()

		// wait for the command to exit, then close the websocket
		cmd.Wait()
	}
	defer fmt.Printf("Websocket session closed for %v", r.RemoteAddr)

	// start the websocket session:
	websocket.Handler(wsHandler).ServeHTTP(w, r)
}

func main() {
	router := mux.NewRouter()
	gorilla := gorilla.NewGorillaServer(router)

	// Health REST service endpoint
	router.HandleFunc("/api/health", func(res http.ResponseWriter, req *http.Request) {
		type health struct {
			Status    string `json:"status"`
			Home      string `json:"home"`
			Name      string `json:"name"`
			Version   string `json:"version"`
			Build     string `json:"build"`
			Timestamp int64  `json:"timestamp"`
		}
		n := gorilla.Ctx.Env.GetStringEnv("VCAP_APPLICATION", "name")
		v := gorilla.Ctx.Env.GetStringEnv("VCAP_APPLICATION", "version")
		b := gorilla.Ctx.Env.GetStringEnv("build")

		m := &health{Status: "up", Name: n, Version: v, Build: b, Timestamp: web.CurrentTimestamp()}

		gorilla.HandleJson(m, res, req)
	})

	//
	router.HandleFunc("/shell/", func(res http.ResponseWriter, req *http.Request) {
		sh(res, req)
	})

	// Serve static files from static/ folder if found
	// or else show the following default page
	defaultPage := `<html><body><a href="/api/health">Health Service</a><br />Current Time: %v</body></html>`

	pwd, _ := os.Getwd()
	fmt.Printf("Working directory: %s\n", pwd)

	if _, err := os.Stat(files); err == nil {
		fmt.Printf("Serving files from: %s/%s \n", pwd, files)

		router.PathPrefix("/").Handler(http.StripPrefix("/", http.FileServer(http.Dir(files))))
	} else {

		fmt.Printf("Directory %s missing in %s\n", files, pwd)

		router.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
			res.Header().Set("Content-Type", web.ContentType.HTML)
			res.WriteHeader(http.StatusOK)

			now := web.CurrentTimestamp()
			html := fmt.Sprintf(defaultPage, now)

			fmt.Fprintf(res, html)
		})
	}

	fmt.Print(gorilla)

	web.Run(gorilla)
}