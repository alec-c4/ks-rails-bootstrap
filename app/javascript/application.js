// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "bootstrap";
import LocalTime from "local-time";
import "./controllers";
import "./timezone";

LocalTime.start();
