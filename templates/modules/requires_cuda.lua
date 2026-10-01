{% extends "modules/modulefile.lua" %}
{% block autoloads %}

-- Require CUDA module
prereq("cuda")

{{ super() }}
{% endblock %}
