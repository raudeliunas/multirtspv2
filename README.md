RTSP to HTTPS Gateway

A simple gateway to stream RTSP feeds from IP cameras over HTTPS using Docker.
It converts the RTSP feed into a browser-accessible format served through NGINX with a self-signed certificate.

📦 Prerequisites

Make sure you have the following installed:

Docker

Docker Compose

🚀 Getting Started

1. Clone the repository: git clone https://github.com/raudeliunas/multirtspv2.git

2. cd multirtspv2

3. Make the script executable: chmod +x iniciar.sh

4. Run the setup script: ./iniciar.sh


Select the number of cameras you want to add.

Provide the full RTSP URL for each camera, for example:

rtsp://admin:password@192.168.1.2/Streaming/Channels/102


The script will update .env, docker-compose.yml, and nginx.conf automatically.

4. Access the streams

Once running, streams will be available at:

https://localhost/cam1
https://localhost/cam2
...
https://localhost/camX

5. Stop the containers
docker compose down

⚙️ Additional Configuration
HTTPS & Certificates

NGINX is configured to serve streams via HTTPS.

A self-signed certificate is included for the host https://cameras.

To download it, open:

https://localhost

Local Hostname Setup (Windows)

To access streams via https://cameras, configure your hosts file:

Open the file:

C:\Windows\System32\drivers\etc\hosts


Add an entry at the end:

192.168.1.100 cameras


Replace 192.168.1.100 with the IP of the server running Docker.

Save the file.

Now you can access streams in your browser at:
https://cameras/cam1, https://cameras/cam2, etc.

📷 Camera Configuration

Default streaming setup: 640x480 resolution @ 5 FPS.

For best performance and lower CPU usage, configure your camera to a similar resolution and frame rate.

Higher resolutions or FPS will increase system resource usage during video conversion.

📄 License

This project is licensed under the MIT License.