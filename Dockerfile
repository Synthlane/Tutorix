FROM frappe/bench:latest

ENV NODE_OPTIONS="--max-old-space-size=4096"

USER root

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    mariadb-client \
    redis-tools \
    gosu \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install watchdog for file watching
RUN pip3 install --no-cache-dir watchdog

# Initialize a new bench
WORKDIR /workspace
RUN chown -R frappe:frappe /workspace

USER frappe

# Initialize bench
RUN bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench

WORKDIR /workspace/frappe-bench

# Copy apps into the bench
COPY --chown=frappe:frappe apps/frappe /workspace/frappe-bench/apps/frappe
COPY --chown=frappe:frappe apps/payments /workspace/frappe-bench/apps/payments  
COPY --chown=frappe:frappe apps/lms /workspace/frappe-bench/apps/lms

# The frappe repo vendors a bunch of JS/CSS libraries under frappe/public/js/lib.
# In some clones these folders are missing (to keep the repo light), which causes
# `bench build` to fail and leaves CSS/JS assets unbuilt. Fetch them from upstream
# if the directory is absent so that every image build has the required sources.
RUN if [ ! -d "/workspace/frappe-bench/apps/frappe/frappe/public/js/lib" ]; then \
        echo "Downloading frappe/public/js/lib from upstream (version-15)..." && \
        git clone --depth 1 --branch version-15 https://github.com/frappe/frappe.git /tmp/frappe-src && \
        mkdir -p /workspace/frappe-bench/apps/frappe/frappe/public/js/lib && \
        cp -a /tmp/frappe-src/frappe/public/js/lib/. /workspace/frappe-bench/apps/frappe/frappe/public/js/lib/ && \
        rm -rf /tmp/frappe-src; \
    fi

# Install the apps into the bench virtual environment
RUN ./env/bin/pip install --no-cache-dir -e ./apps/frappe && \
    ./env/bin/pip install --no-cache-dir -e ./apps/payments && \
    ./env/bin/pip install --no-cache-dir -e ./apps/lms

# Install node dependencies
RUN cd apps/frappe && yarn install && \
    cd ../lms && yarn install

# Register apps with bench
RUN printf "frappe\npayments\nlms\n" > sites/apps.txt

# Build assets for all apps
RUN bench build

# Copy startup script
USER root
COPY docker-entrypoint.sh /usr/local/bin/
COPY start.sh /workspace/frappe-bench/
COPY reload-doc-watcher.py /workspace/frappe-bench/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /workspace/frappe-bench/start.sh /workspace/frappe-bench/reload-doc-watcher.py && \
    chown frappe:frappe /workspace/frappe-bench/start.sh /workspace/frappe-bench/reload-doc-watcher.py

# Create directories and fix permissions
RUN mkdir -p /workspace/frappe-bench/logs /workspace/frappe-bench/sites && \
    chown -R frappe:frappe /workspace/frappe-bench

# Expose ports
EXPOSE 8000 9000

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["/workspace/frappe-bench/start.sh"]
