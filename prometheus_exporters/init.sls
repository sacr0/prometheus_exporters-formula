{% from "prometheus_exporters/map.jinja" import exporters with context %}

# install package and run servie
{% for exporter_name, exporter_details in exporters.iteritems() %}
exporter_{{ exporter_name }}:
  pkg.installed:
    - name: {{ exporter_details.pkg }}
  service.running:
    - enable: True
    - name: {{ exporter_details.service }}
	- require:
      - pkg: exporter_{{ exporter_name }}
  file.managed:
    - name: {{ exporter_details.configfile }}
	- contents: {{ exporter_details.configuration }}

{% if 'textfile_collectors' in exporter_details and exporter_details.collector_textfile_dir %}
exporter_collector_textfile_dir:
  file.managed:
    - name: {{ exporter_details.collector_textfile_dir }}
	- user: {{ exporter_name }}
	- group: {{ exporter_name }}

{% for collector, config in exporter_details.textfile_collectors.iteritems() %}
prometheus-exporters-install-textfile_collector-{{ collector }}:
  pkg.installed:
    - names:
      - {{ config.pkg }}
  file.managed:
    - name: {{ exporter_details.collector_textfile_script_dir }}/{{ config.scriptname }}
    - source: salt://prometheus_exporters/files/textfile_collectors/{{ config.scriptname }}.jinja
    - template: jinja
    - mode: 755
  cron.present:
    - identifier: prometheus-exporters-{{ exporter_name }}-textfile_collectors-{{ collector }}-cronjob
    - name: cd {{ exporter_details.collector_textfile_dir }} && LANG=C {{ exporter_details.collector_textfile_script_dir }}/{{ config.scriptname }} > .smartmon.prom$$ && mv .smartmon.prom$$ smartmon.prom
    - minute: "{{ config.get('minute', '*') }}"
    - comment: Prometheus' {{ exporter_name }}'s {{ collector }} textfile collector
    - require:
	  - pkg: prometheus-exporters-install-textfile_collector-{{ collector }}
      - file: prometheus-exporters-install-textfile_collector-{{ collector }}
{% endfor %}
{% endif %}

{% endfor %}