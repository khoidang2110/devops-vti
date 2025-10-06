# 🚀 Cài đặt Harbor trên AWS Linux 2023

## 1. SSH vào EC2

```
ssh -i ~/Downloads/khoidang.pem ec2-user@3.107.182.54
```

---

## 2. Cập nhật hệ thống

```
sudo dnf update -y
```

---

## 3. Cài đặt Docker

```
sudo dnf install -y docker

# Start Docker và enable service
sudo systemctl start docker
sudo systemctl enable docker

# Thêm user ec2-user vào group docker (để chạy không cần sudo)
sudo usermod -aG docker ec2-user

# Thoát và login lại để áp dụng group
exit
```

---

## 4. Cài Docker Compose

```
DOCKER_COMPOSE_VERSION=v2.23.0

sudo curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

docker-compose --version
```

---

## 5. Chuẩn bị thư mục Harbor

```
mkdir harbor-standalone
cd harbor-standalone

curl -LO https://github.com/goharbor/harbor/releases/download/v2.11.0/harbor-online-installer-v2.11.0.tgz
tar xzvf harbor-online-installer-v2.11.0.tgz
cd harbor
```

---

## 6. Cấu hình Harbor

 tạo mới:

```
nano harbor.yml
```

(chép nội dung harbor.yml vào)


---

## 7. Cài đặt Harbor

Chạy installer (cần sudo nếu gặp vấn đề quyền file):

```
sudo ./install.sh
```

---

## 8. Truy cập giao diện Harbor

* Mở trình duyệt: [http://13.55.59.231](http://13.55.59.231)
* Username: admin
* Password: Harbor12345

---

## 9. Notes

* Nếu gặp lỗi permission với `common/config`, chạy lại `install.sh` bằng `sudo`.
* Trên AWS, nhớ mở Security Group cho port 80 hoặc 443 (nếu bật HTTPS).

---

health: starting là chưa khởi động xong, phải healthy.
✅ Giờ Harbor đã sẵn sàng trên EC2!
