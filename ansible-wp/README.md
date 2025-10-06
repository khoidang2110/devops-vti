AWS WordPress Cluster với Ansible

Mục tiêu: Triển khai kiến trúc WordPress cluster trên AWS với:

1 Ansible host để quản lý và cài đặt
2 WordPress servers
1 Database server (PostgreSQL)
1 Load Balancer để cân bằng tải
Network (VPC & Subnets)
VPC CIDR: 10.0.0.0/24
Subnets: Public subnet: cho Ansible host + Load Balancer Private subnet: cho WordPress servers + Database
Internet Gateway: gắn cho public subnet
Route Tables: Public subnet: internet qua IGW Private subnet: chỉ route nội bộ
Security Groups
VPS1 (Ansible): Inbound: SSH từ laptop Outbound: all
VPS2 (DB): Inbound: từ WordPress servers + SSH từ Ansible host Outbound: all hoặc internal
VPS3 & VPS4 (WordPress): Inbound: từ Load Balancer + SSH từ Ansible host Outbound: all
VPS5 (Load Balancer): Inbound: HTTP/HTTPS từ internet Outbound: HTTP/HTTPS tới WordPress servers
Key Pair
Dùng chung cho tất cả EC2
Lưu file .pem cẩn thận
Flow kết nối Laptop -> SSH -> Ansible host -> SSH -> WordPress/DB User -> HTTP/HTTPS -> Load Balancer -> WordPress WordPress -> connect -> DB

Triển khai với Ansible

Cấu hình inventory với private IP của WordPress và DB
Chạy playbook để cài đặt WordPress và DB
LB forward traffic từ internet vào WordPress
Best Practices
Không để Public IP trên WordPress
Dùng SG reference thay vì IP cố định để SSH từ Ansible
DB nằm private, không mở ra internet
LB public, WordPress private nhận traffic từ LB
Notes
Private IP có thể thay đổi khi stop/start EC2
Nếu DB cần update package, thêm NAT Gateway cho private subnet