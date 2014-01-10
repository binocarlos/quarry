FROM quarry/node
ADD . /opt/quarry
RUN cd /opt/quarry && npm install
RUN cd /opt/quarry && npm link