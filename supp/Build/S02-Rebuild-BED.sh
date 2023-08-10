#/bin/bash

# R -e "Sys.setenv(PATH=paste(Sys.getenv('PATH'), '/usr/lib/rstudio-server/bin/pandoc', sep=':')); rmarkdown::render('Rebuild-BED.Rmd')";
# R -e "Sys.setenv(PATH=paste(Sys.getenv('PATH'), '/usr/lib/rstudio-server/bin/quarto/bin', sep=':')); Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio-server/bin/pandoc'); rmarkdown::render('Rebuild-BED.Rmd')";
R -e "Sys.setenv(PATH=paste(Sys.getenv('PATH'), '/usr/lib/rstudio-server/bin/quarto/bin', sep=':')); Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio-server/bin/quarto/bin/tools'); rmarkdown::render('Rebuild-BED.Rmd')";
