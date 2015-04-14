#!/bin/bash

DEPS=(markdown wkhtmltopdf)
FILENAME='DockerDayII.pdf'

for DEP in ${DEPS[@]} ; do
if [[ ! $(which ${DEP}) ]] ; then
  echo -e "\nERROR: ${DEP} is required to convert to pdf."
  echo -e "\nRequirements: \n\n\t${DEPS[@]}\n"
  exit 1
fi
done

markdown README.md | sed 's|<hr />|<br />|' | sed '1s/^/<html>/' |sed -e "\$a</html>"  |wkhtmltopdf - ${FILENAME}  && echo "Saved to ${FILENAME}"
