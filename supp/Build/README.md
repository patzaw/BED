## Update resource

1. *(Optional)* draft a new version in Zenodo and take the record identifier
from the url (digits after the last /)

2. Update build_config.json and deploy_config.json files:
   - BED_VERSION: "Year.Month.Day" (e.g. "2024.04.27")
   - *(Optional)* ZENODO_RECORD (see optional step 1)

3. *(Optional)* Run script `S00-Prepare-large-files.sh` in low cost environment:
this step takes a lot of time

4. Create and/or get access to a computing instance with at least
100GB of memory (e.g., the "r2-120" instance
at [OVHcloud](https://www.ovhcloud.com/en/public-cloud/prices/);
see the "requirements" folder)

5. Instantiate a Neo4j container with script `S01-NewBED-Container.sh`

6. Build the database with script `S02-Rebuild-BED.sh`

7. *(Optional)* Dump the database with script `S03-Dump-BED.sh`

8. *(Optional)* Push the dumped database on Zenodo with
script `S11-Push-on-Zenodo.sh`

9. *(Optional)* Publish the draft version in Zenodo

10. *(Optional)* Deploy the new database in any environment with docker
with script `S21-Deploy-from-Zenodo.sh`
