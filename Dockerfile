FROM hugomods/hugo:exts-0.148.0 AS builder
WORKDIR /src

COPY . .

RUN hugo --minify

FROM nginx:alpine

COPY --from=builder /src/public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
