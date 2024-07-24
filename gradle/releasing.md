### Steps to follow

- Create local branch e.g. `release-1.0.0` (optional)
- Update the version to `version = '1.0.0'` in `sprotty-server/gradle/versions.gradle` and commit
- Make sure `SONATYPE_USERNAME` and `SONATYPE_PASSWORD` env variables contain the proper __TOKEN__ login information
  1. Go to https://oss.sonatype.org/
  2. Go to profile
  3. Change the pulldown from “Summary” to “User Token”
  4. Click on “Access User Token”

- Run `./gradlew clean publish -P signing.gnupg.passphrase=<SECRET>`. `<SECRET>` is the passphrase for your pgp key.
- Go to [OSS Staging Repository](https://oss.sonatype.org/#stagingRepositories) and __Close__ -> __Release__ the staging repositories
- Check the released version inside the [maven repo](https://repo1.maven.org/maven2/org/eclipse/sprotty/)
- Create a tag named `v1.0.0` and push tag to remote
- Switch to master. Change gradle version to next snapshot e.g. 1.1.0-SNAPSHOT and commit.
