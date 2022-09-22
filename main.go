package main

import (
	"context"
	"deadfly/pkg/api"
	"log"
	"net/http"
	"os"
	"sync"

	"github.com/caarlos0/env/v6"
)

type config struct {
	Production        bool   `env:"PRODUCTION" envDefault:"false"`
	EnableSleepMode   bool   `env:"ENABLE_SLEEP_MODE" envDefault:"true"`
	SleepAfterSeconds int    `env:"SLEEP_AFTER_SECONDS" envDefault:"10"`
	ProxyURL          string `env:"PROXY_URLS" envDefault:"http://localhost:8000"`
	ListenAddr        string `env:"LISTEN_ADDR" envDefault:"0.0.0.0:4466"`
}

func main() {

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	wg := &sync.WaitGroup{}
	wg.Add(1)
	config := &config{}

	if err := env.Parse(config); err != nil {
		log.Fatalln("parse env", err)
	}

	handler := api.NewHandler(config.EnableSleepMode,
		config.Production,
		config.SleepAfterSeconds,
		config.ProxyURL,
		cancel)
	srv := http.Server{
		Addr:    config.ListenAddr,
		Handler: handler,
	}

	log.Printf("Server Listening on: http://%s", config.ListenAddr)
	go func() {
		err := srv.ListenAndServe()
		if err != nil && err != http.ErrServerClosed {
			log.Fatalln("listen and serve", err)
		}
	}()
	<-ctx.Done()
	wg.Done()
	wg.Wait()
	os.Exit(0)
}
