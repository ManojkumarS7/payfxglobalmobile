# Fix for XMLStreamException
-keep class javax.xml.stream.** { *; }
-dontwarn javax.xml.stream.**

# Keep Apache Tika (if used by any dependency)
-keep class org.apache.tika.** { *; }
-dontwarn org.apache.tika.**