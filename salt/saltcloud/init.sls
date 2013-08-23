# base packages
salt-cloud-deps:
  pkg.installed:
    - pkgs:
      - sshpass
      - python-pip

# the underlying cloud library
apache_libcloud:
  pip.installed:
    - name: apache_libcloud
    - require:
      - pkg: salt-cloud-deps

# salt cloud itself
salt-cloud:
  pip.installed:
    - name: salt-cloud
    - require:
      - pip: apache_libcloud

# loop the cloud providers and include them in the salt-cloud folders
{% for name, provider in pillar.cloud.iteritems() %}

salt-cloud-provider-{{ name }}:
  file.managed:
    - name: /etc/salt/cloud.providers.d/{{ name }}.conf
    - source: salt://saltcloud/{{ name }}/provider.conf
    - template: jinja
    - makedirs: True
    - mode: 664
    - require:
      - pip: salt-cloud

salt-cloud-profiles-{{ name }}:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/{{ name }}.conf
    - source: salt://saltcloud/{{ name }}/profiles.conf
    - template: jinja
    - makedirs: True
    - mode: 664
    - require:
      - pip: salt-cloud

{% endfor %}

