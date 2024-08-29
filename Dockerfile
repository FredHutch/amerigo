FROM fredhutch/r-shiny-server-base:4.3.0
RUN apt-get update -y && apt-get install -y pandoc libudunits2-dev libproj22 libgdal-dev
RUN R -q -e 'install.packages(c("shiny", "bslib", "sf", "leaflet", "RColorBrewer", "readr", "stringr", "dplyr", "htmltools", "desc"))'


RUN rm -rf /srv/shiny-server/
ADD *.R /srv/shiny-server/

ADD ./app /srv/shiny-server/
ADD check.R /tmp/

RUN chown -R shiny:shiny /srv/shiny-server/

EXPOSE 3838

WORKDIR /srv/shiny-server

RUN R -f /tmp/check.R --args shiny bslib sf leaflet RColorBrewer readr stringr dplyr htmltools desc

RUN rm /tmp/check.R

ENV SHINY_LOG_STDERR=1 

CMD ["/usr/bin/shiny-server"]