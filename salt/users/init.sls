{% for user, args in pillar['users'].iteritems() %}
user-{{ user }}:
  group.present:
    - name: {{ user }}
  user.present:
    - name: {{ user }}
    - shell: /bin/bash
    - home: /home/{{ user }}
    - groups:
      - {{ user }}
{% endfor %}