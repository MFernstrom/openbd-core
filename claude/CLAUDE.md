# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About OpenBD

OpenBD is an open source GPLv3.0 Java CFML (ColdFusion Markup Language) runtime engine. It was the world's first truly open source CFML runtime, first created in 2000. The project is no longer being actively maintained but has a long legacy.

## Build Commands

OpenBD uses Apache Ant for builds. All build scripts are in `./build/build.xml`.

**Core build commands:**
```bash
# Compile only (creates OpenBlueDragon.jar)
ant -buildfile build/build.xml compile

# Build standard WAR file
ant -buildfile build/build.xml war

# Build WAR with manual and admin console
ant -buildfile build/build.xml war-with-manual

# Build ready-to-run Jetty package
ant -buildfile build/build.xml ready2run

# Clean build artifacts
ant -buildfile build/build.xml clean
```

**Output locations:**
- All build artifacts: `./build/targets/`
- Compiled classes: `./build/classes/`
- WAR staging: `./build/war/`

**Parser regeneration (requires JavaCC):**
```bash
# Regenerate CFML expression parser
ant -buildfile build/build.xml javaccexpressionengine

# Regenerate CFScript parser
ant -buildfile build/build.xml javacccfscript

# Regenerate Query-of-Queries SQL parser
ant -buildfile build/build.xml javaccqoq
```

Note: After regenerating parsers, replace 'enum' references with 'enumer' for Java compatibility.

## Requirements

- Java JDK 8 or newer (JDK required, not JRE)
- Apache Ant (http://ant.apache.org/)
- Optional: Eclipse IDE (project files included)

**Note on Java Versions:**
- The codebase has been updated to work with Java 9+ without requiring tools.jar
- Uses modern `javax.tools.JavaCompiler` API for runtime compilation
- For Java 8, ensure you're running on a JDK (tools.jar is automatically available)
- For Java 9+, the compiler API is part of the standard JDK modules

## High-Level Architecture

### Core Engine Components

**Main Entry Point:**
- `src/com/naryx/tagfusion/cfm/cfServlet.java` - HttpServlet that bootstraps the engine
- `src/com/naryx/tagfusion/cfm/engine/cfEngine.java` - Central orchestration, singleton pattern
  - Manages lifecycle (init, service, destroy)
  - Loads configuration from `bluedragon.xml`
  - Initializes all subsystems (plugins, cache, file cache, datasources)

**Request/Session Management:**
- `src/com/naryx/tagfusion/cfm/engine/cfSession.java` - Represents single request/response cycle
  - Contains request context and variable scopes
  - Manages output buffering, query caching, transactions
  - Tracks component/function call stacks

### Three-Layer Architecture

**1. Expression Engine Layer**
- `src/com/naryx/tagfusion/expression/compile/expressionEngine.java` - Function registry (~600+ functions)
- `src/com/naryx/tagfusion/cfm/engine/registerTagsExpressions.java` - Registers all functions/tags at startup
- Function implementations organized by category in: `src/com/naryx/tagfusion/expression/function/{array,string,list,struct,query,xml,file,image,system}/`

**2. Tag Fusion Layer**
- `src/com/naryx/tagfusion/cfm/tag/tagChecker.java` - Tag registry and discovery (97+ tags)
- Tag implementations: `src/com/naryx/tagfusion/cfm/tag/` (all extend `cfTag`)
- Custom tag support via `cfCustomTag` mechanism

**3. CFML Script Processing**
- Parser: `src/com/naryx/tagfusion/cfm/parser/` (ANTLR-based)
- Grammars: `CFML.g`, `CFMLTree.g` (generates CFMLParser, CFMLLexer)
- Script statements: `src/com/naryx/tagfusion/cfm/parser/script/` (if, switch, for, while, try/catch, etc.)

### Data Type System

**Base class:** `src/com/naryx/tagfusion/cfm/engine/cfData.java`

**Core types:** cfStringData, cfNumberData, cfBooleanData, cfDateData, cfArrayData, cfStructData, cfQueryResultData, cfComponentData, cfBinaryData, cfNullData, cfJavaObjectData

Type system supports Java interop via JavaCast mechanism.

### Plugin Architecture

**Plugin Manager:** `src/com/bluedragon/plugin/PluginManager.java`
- Auto-discovers plugins via JAR scanning (pattern: `openbdplugin-*.jar`)
- Lifecycle: `pluginStart()`, request hooks (RequestListener interface)
- Can override core functions via `server.system.pluginoverride` flag

**Built-in Plugins:**
- SpreadSheetExtension (Excel/ODS)
- SmtpExtension (SMTP server)
- LoginExtension (authentication)
- CronExtension (scheduled tasks)
- MongoExtension (MongoDB - 30+ functions)
- SalesForceExtension (Salesforce API)
- VisionExtension (advanced features)
- ProfilerExtension (performance profiling)

**Extension points:** Functions, tags, request listeners

### Database and Query Handling

**Connection Pooling:** `src/com/naryx/tagfusion/cfm/sql/pool/DataSourcePoolFactory.java`
- Dual pool strategy: Long-term pools (limited) and Short-term pools (unlimited)
- Supports J2EE DataSource integration
- Platform-specific implementations: `src/com/naryx/tagfusion/cfm/sql/platform/`

**Query Components:**
- `cfQUERY.java` - Main CFQUERY tag
- `cfSQLQueryData.java` - Query execution/results
- `preparedData.java` - Prepared statement caching

**Query of Queries (QoQ):** `src/com/naryx/tagfusion/cfm/queryofqueries/`
- Separate in-memory SQL engine with JavaCC parser (`selectsql.jj`)
- Supports JOIN, GROUP BY, aggregate functions

### Session/Application Scope Management

**Application Manager:** `src/com/naryx/tagfusion/cfm/application/cfApplicationManager.java`
- Manages application/session timeouts and OnApplicationEnd events
- Client storage abstraction (Cookie, Database, Redis)

**Scope implementations:**
- cfApplicationData, cfSessionData (traditional CFML)
- cfJ2EESessionData (servlet session integration)
- cfClientSessionData, cfClientDataManager

**Session backends:** Cookie-based (default), Database-backed, Redis-backed

### File Caching and Compilation

**File Cache:** `src/com/naryx/tagfusion/cfm/file/cfmlFileCache.java`
- LRU cache for parsed CFML files (default: 1000 files)
- Trust cache mode for production
- CF mapping support
- VFS integration (Apache Commons VFS) for virtual file systems

### Major Subsystems

**MongoDB:** `src/com/bluedragon/mongo/` - MongoExtension plugin with 30+ functions (collection ops, GridFS)

**Redis:** Cache backend (`RedisCacheImpl.java`) and session storage (`SessionStorageRedisCacheImpl.java`)

**Cache Framework:** `src/com/naryx/tagfusion/cfm/cache/`
- Factory pattern for cache regions (CacheFactory.java)
- Backends: MemoryDiskCacheImpl (LRU), RedisCacheImpl, MongoCacheImpl, MemcachedCacheImpl
- Function result caching built-in

**AWS Integrations:** `src/org/alanwilliamson/amazon/` - S3, SimpleDB, SQS, Lambda, Elastic Transcoder

**Search:** `src/com/bluedragon/search/` - Lucene-based full-text search

**Web Services:** `src/com/naryx/tagfusion/cfm/xml/ws/` - SOAP client/server, dynamic WSDL generation

**Mail Server:** `src/org/alanwilliamson/mail25/` - Full SMTP server with mailet chain processing

**Journal System:** `src/com/bluedragon/journal/` - Request recording/replay for debugging

## Key Design Patterns

**Registry Pattern:** Central registries for functions (expressionEngine) and tags (tagChecker) with dynamic loading

**Factory Pattern:** CacheFactory, DataSourcePoolFactory, ComponentFactory, cfDataFactory

**Platform Abstraction:** Platform interface with JavaPlatform implementation for portability

**Component-Based:** CFC (ColdFusion Component) support with metadata introspection, inheritance, method overriding

**Parser Generation:** ANTLR for CFML expressions, JavaCC for QoQ SQL - generated parsers are committed to source

**Request Lifecycle Hooks:** RequestListener interface for plugins (requestStart, requestEnd, exceptions)

## Configuration

**Primary config:** `webapp/WEB-INF/bluedragon/bluedragon.xml`
- System settings, datasources, debugging, mail, custom tags, mappings
- Runtime reloadable for certain settings

**Build version:** `build/openbd.properties` - Contains version, state, release/build dates

## Code Organization

```
src/
├── com/naryx/tagfusion/          # Core CFML engine
│   ├── cfm/engine/               # Engine core (cfEngine, cfSession, cfData types)
│   ├── cfm/tag/                  # Tag implementations (97+ tags)
│   ├── cfm/parser/               # CFML parser (ANTLR-based)
│   ├── cfm/application/          # Application/session scope management
│   ├── cfm/cache/                # Cache framework
│   ├── cfm/file/                 # File cache and compilation
│   ├── cfm/sql/                  # Database/query handling
│   ├── cfm/queryofqueries/       # Query-of-Queries engine
│   ├── cfm/xml/ws/               # Web services
│   └── expression/               # Expression engine and functions
├── com/bluedragon/               # Extensions and plugins
│   ├── plugin/                   # Plugin architecture
│   ├── mongo/                    # MongoDB integration
│   ├── search/                   # Lucene search
│   ├── vision/                   # Advanced monitoring
│   └── journal/                  # Request recording
├── org/alanwilliamson/           # Third-party integrations
│   ├── amazon/                   # AWS integrations
│   ├── mail25/                   # SMTP server
│   └── openbd/                   # OpenBD utilities
├── coldfusion/                   # ColdFusion compatibility adapter
└── org/m0zilla/javascript/       # Embedded Mozilla Rhino JavaScript engine

webapp/
└── WEB-INF/
    ├── lib/                      # Runtime dependencies (JARs)
    ├── bluedragon/               # Configuration files
    └── webresources/             # Static web resources

build/
├── build.xml                     # Ant build script
├── lib/                          # Build-time dependencies
└── resources/                    # Build resources
```

## Important Notes

- This is a legacy codebase that is no longer actively maintained
- Java 8+ is supported (codebase uses Java 8 features)
- All parsers are generated from grammar files but committed to source control
- The dual connection pooling strategy (long-term/short-term) is critical for production deployments
- Plugin system allows runtime extension without core modifications
- File cache and trust cache settings significantly impact performance

## Known Build Issues

**Java Applet Classes (Browser Plugin API):**
The following files fail to compile on newer Java versions due to removal of the browser plugin API:
- `src/com/bluedragon/browser/SliderApplet.java`
- `src/com/bluedragon/browser/TextInput.java`
- `src/com/bluedragon/browser/TreeApplet.java`

These files use `JSObject.getWindow()` from the old `plugin.jar`, which was removed in Java 9+. If applet functionality is not needed, these files can be excluded from compilation by modifying `build.xml` to exclude `com/bluedragon/browser/**`.

**tools.jar Dependency:**
The dependency on tools.jar has been removed. The codebase now uses the modern `javax.tools.JavaCompiler` API which works with Java 8+ and doesn't require tools.jar in Java 9+. See `TOOLS_JAR_REMOVAL.md` for details.
