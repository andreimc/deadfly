package api

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
	"time"
)

type Handler struct {
	enableSleepMode   bool
	enablePlayground  bool
	sleepAfterSeconds int
	init              sync.Once
	sleepCh           chan struct{}
	proxyUrl          string
	cancel            func()
}

func NewHandler(enableSleepMode bool, production bool, sleepAfterSeconds int, proxyUrl string, cancel func()) *Handler {

	h := &Handler{
		enableSleepMode:   enableSleepMode,
		enablePlayground:  !production,
		sleepCh:           make(chan struct{}),
		sleepAfterSeconds: sleepAfterSeconds,
		proxyUrl:          proxyUrl,
		cancel:            cancel,
	}

	// Initialise sleep mode
	h.init.Do(func() {
		if h.enableSleepMode {
			go h.runSleepMode()
		}
	})

	return h
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	target := h.proxyUrl
	url, _ := url.Parse(target)
	proxy := httputil.NewSingleHostReverseProxy(url)
	proxy.ServeHTTP(w, r)

	if h.enableSleepMode {
		defer func() {
			h.sleepCh <- struct{}{}
		}()
	}
}

func (h *Handler) runSleepMode() {
	timer := time.NewTimer(time.Duration(h.sleepAfterSeconds) * time.Second)
	defer func() {
		fmt.Println("No requests for", h.sleepAfterSeconds, "seconds, cancelling context")
		h.cancel()
	}()
	for {
		select {
		case <-h.sleepCh:
			done := timer.Reset(time.Duration(h.sleepAfterSeconds) * time.Second)
			if !done {
				return
			}
		case <-timer.C:
			return
		}
	}
}
