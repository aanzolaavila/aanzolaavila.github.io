.PHONY: run
run:
	docker run --rm -it \
  	  -v "$$(pwd):/src" \
  	  -w /src \
  	  -p 1313:1313 \
  	  ghcr.io/gohugoio/hugo:v0.140.1 server --buildDrafts --bind 0.0.0.0 --destination /tmp/hugo_cache
