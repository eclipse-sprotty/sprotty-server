# sprotty-server
Libraries to build [Sprotty diagram](https://github.com/eclipse/sprotty) servers in Java/Xtend.

## Structure
- `org.eclipse.sprotty`: Java bindings for the Sprotty API.
- `org.eclipse.sprotty.layout`: Server-based layout using the [Eclipse Layout Kernel](https://www.eclipse.org/elk/) framework
- `org.eclipse.sprotty.server`: Base library for standalone Sprotty servers.
- `org.eclipse.sprotty.xtext`: Glue code to integrate Sprotty diagrams with Xtext-based Language Servers. Enhances 
the LSP to communicate Sprotty Actions. Allows fully synchronized diagrams on language artifacts.

## Build
```bash
./gradlew build
```

Pre-build Maven artifacts are available from [Sonatype OSS](https://oss.sonatype.org/content/repositories/snapshots/org/eclipse/sprotty/).

## See also

- [sprotty](https://github.com/eclipse/sprotty) the client part of the Sprotty framework. 
- [sprotty-theia](https://github.com/eclipse/sprotty-theia) integrate Sprotty diagrams in extensions to the [Theia IDE](https://theia-ide.org)

## References

- [DSL in the Cloud example](http://github.com/TypeFox/theia-xtext-sprotty-example) an example using Xtext, Theia and Sprotty to create a DSL workbench in the cloud.
- [yangster](http://github.com/theia-ide/yangster) a Theia extension for the YANG language.
