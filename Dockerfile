# Gunakan nginx ringan sebagai web server
FROM nginx:alpine

# Salin semua file aplikasi ke folder yang dilayani nginx
COPY . /usr/share/nginx/html

# Pastikan nginx melayani dengan tipe MIME yang benar
RUN echo 'server { \
  listen 80; \
  root /usr/share/nginx/html; \
  index index.html; \
  location / { \
    try_files $uri $uri/ /index.html; \
    add_header Cache-Control "no-cache"; \
  } \
  location ~* \.(webmanifest|json)$ { \
    add_header Content-Type application/json; \
  } \
}' > /etc/nginx/conf.d/default.conf

# Port yang digunakan
EXPOSE 80
