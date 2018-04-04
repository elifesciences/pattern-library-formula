#!/bin/bash
. /opt/smoke.sh/smoke.sh

smoke_url_ok localhost/
smoke_url_ok localhost/styleguide/css/styleguide.css
smoke_url_ok localhost/styleguide/html/styleguide.html

smoke_report
