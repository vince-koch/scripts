## scoop
	- git
	- gitui

## scripts repository
	git clone https://github.com/vince-koch/scripts.git

## mitmproxy
    - Install mitmproxy as a docker image
        ```shell
        docker run --rm -it -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 -p 8081:8081 mitmproxy/mitmproxy
        ```
    - Open http://mitm.it from the browser which will be using mitmproxy
    - Install the certificate
    - See the following [article](https://scrapfly.io/blog/how-to-install-mitmproxy-certificate/) for additional information