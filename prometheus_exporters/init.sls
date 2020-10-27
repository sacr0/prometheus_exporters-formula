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
{% if 'configfile' in exporter_details and exporter_details.configfile %}
  file.managed:
    - name: {{ exporter_details.configfile }}
    - contents: {{ exporter_details.configuration }}
{% endif %}

{% if 'textfile_collectors' in exporter_details and exporter_details.collector_textfile_script_dir %}
exporter_collector_textfile_output_dir:
  file.directory:
    - name: {{ exporter_details.collector_textfile_output_dir }}
    - user: {{ exporter_name }}
    - group: {{ exporter_name }}
    - makedirs: true

{% for collector, config in exporter_details.textfile_collectors.iteritems() %}
prometheus-exporters-install-textfile_collector-{{ collector }}:
  pkg.installed:
    - names:
      - {{ config.pkg }}
  file.managed:
    - name: {{ exporter_details.collector_textfile_script_dir }}/{{ config.scriptname }}
    - source: salt://prometheus_exporters/files/textfile_collectors/{{ config.scriptname }}
    - mode: 755
    - makedirs: true
  cron.present:
    - identifier: prometheus-exporters-{{ exporter_name }}-textfile_collectors-{{ collector }}-cronjob
    - name: cd {{ exporter_details.collector_textfile_output_dir }} && LANG=C {{ exporter_details.collector_textfile_script_dir }}/{{ config.scriptname }} > .smartmon.prom$$ && mv .smartmon.prom$$ smartmon.prom
    - minute: "{{ config.get('minute', '*') }}"
    - comment: Prometheus' {{ exporter_name }}'s {{ collector }} textfile collector
    - require:
      - pkg: prometheus-exporters-install-textfile_collector-{{ collector }}
      - file: prometheus-exporters-install-textfile_collector-{{ collector }}
{% endfor %}
{% endif %}

{% endfor %}
