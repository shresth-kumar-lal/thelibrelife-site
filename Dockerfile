FROM hugomods/hugo:debian-reg-dart-sass-node-0.160.1 AS builder
WORKDIR /src

COPY . .

RUN hugo --minify

FROM nginx:alpine

COPY --from=builder /src/public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
