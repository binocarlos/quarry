FROM quarry/node
ADD . /opt/quarry
RUN cd /opt/quarry && npm link