FROM nginx:1.28.0-alpine
COPY index.html version.txt /usr/share/nginx/html/
