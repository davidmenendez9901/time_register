# Flutter / R8: engine rules are applied automatically.
# Keep SQLite JNI bindings used by sqflite.

-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

-dontwarn com.google.android.play.core.**
