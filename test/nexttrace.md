nexttrace --fast-trace

wget -qO /usr/local/bin/nexttrace https://github.com/nxtrace/NTrace-core/releases/download/v1.7.1/nexttrace_linux_amd64 && chmod +x /usr/local/bin/nexttrace && nexttrace --fast-trace

LATEST=$(curl -s https://api.github.com/repos/nxtrace/NTrace-core/releases/latest | grep -o '"tag_name": *"v[^"]*"' | cut -d'"' -f4) && wget -qO /usr/local/bin/nexttrace "https://github.com/nxtrace/NTrace-core/releases/download/$LATEST/nexttrace_linux_amd64" && chmod +x /usr/local/bin/nexttrace && nexttrace --fast-trace
