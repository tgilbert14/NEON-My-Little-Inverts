# Shared fail-closed path checks for release writers. Recursive list.files()
# follows linked directories, so checking only the final file is insufficient.

inv_path_fail <- function(...) stop(sprintf(...), call. = FALSE)

inv_path_normalize_relative <- function(paths, label) {
  paths <- gsub("\\\\", "/", as.character(paths))
  unsafe <- is.na(paths) | !nzchar(paths) |
    grepl("[\r\n\t]", paths) |
    startsWith(paths, "/") |
    grepl("^[A-Za-z]:($|/)", paths) |
    grepl("(^|/)[.][.]?(/|$)", paths)
  if (!length(paths) || any(unsafe) || anyDuplicated(paths)) {
    inv_path_fail("%s paths are empty, duplicated, or unsafe", label)
  }
  paths
}

inv_path_component_prefixes <- function(root, relative) {
  components <- strsplit(relative, "/", fixed = TRUE)[[1L]]
  vapply(seq_along(components), function(index) {
    file.path(root, paste(components[seq_len(index)], collapse = "/"))
  }, character(1))
}

inv_assert_safe_relative_paths <- function(root, paths, label,
                                           expected = c("file", "directory")) {
  expected <- match.arg(expected)
  paths <- inv_path_normalize_relative(paths, label)
  if (!dir.exists(root)) inv_path_fail("%s root does not exist", label)
  root_real <- normalizePath(root, winslash = "/", mustWork = TRUE)
  boundary <- paste0(root_real, "/")

  for (relative in paths) {
    absolute <- file.path(root, relative)
    prefixes <- inv_path_component_prefixes(root, relative)
    links <- Sys.readlink(prefixes)
    linked <- !is.na(links) & nzchar(links)
    if (any(linked)) {
      inv_path_fail(
        "%s must not contain symbolic-link components: %s",
        label, paste(relative, basename(prefixes[linked][[1L]]), sep = " -> ")
      )
    }
    if (!file.exists(absolute)) {
      inv_path_fail("%s is missing path: %s", label, relative)
    }
    if (identical(expected, "file") &&
        (dir.exists(absolute) || is.na(file.info(absolute)$size))) {
      inv_path_fail("%s is not a regular release file: %s", label, relative)
    }
    if (identical(expected, "directory") && !dir.exists(absolute)) {
      inv_path_fail("%s is not a release directory: %s", label, relative)
    }
    resolved <- normalizePath(absolute, winslash = "/", mustWork = TRUE)
    if (!startsWith(resolved, boundary)) {
      inv_path_fail("%s escapes its release root: %s", label, relative)
    }
  }
  invisible(paths)
}

inv_prepare_safe_output <- function(root, relative, label) {
  relative <- inv_path_normalize_relative(relative, label)
  if (length(relative) != 1L) {
    inv_path_fail("%s must name exactly one output", label)
  }
  parent <- dirname(relative)
  dir.create(file.path(root, parent), recursive = TRUE, showWarnings = FALSE)
  if (!identical(parent, ".")) {
    inv_assert_safe_relative_paths(root, parent, label, expected = "directory")
  } else if (!dir.exists(root)) {
    inv_path_fail("%s root does not exist", label)
  }
  absolute <- file.path(root, relative)
  leaf_link <- Sys.readlink(absolute)
  if (!is.na(leaf_link) && nzchar(leaf_link)) {
    inv_path_fail("%s output must not be a symbolic link: %s", label, relative)
  }
  if (file.exists(absolute)) {
    inv_assert_safe_relative_paths(root, relative, label, expected = "file")
  }
  invisible(absolute)
}

inv_list_release_files <- function(root, directory, all_files = FALSE,
                                   pattern = NULL) {
  directory <- inv_path_normalize_relative(directory, "release directory")
  if (length(directory) != 1L) {
    inv_path_fail("release directory must name exactly one directory")
  }
  inv_assert_safe_relative_paths(
    root, directory, "release directory", expected = "directory"
  )

  walk <- function(relative_directory) {
    absolute_directory <- file.path(root, relative_directory)
    entries <- sort(list.files(
      absolute_directory, recursive = FALSE, full.names = FALSE,
      all.files = TRUE, include.dirs = TRUE, no.. = TRUE
    ), method = "radix")
    output <- character()
    for (entry in entries) {
      relative <- gsub(
        "\\\\", "/", file.path(relative_directory, entry)
      )
      absolute <- file.path(root, relative)
      link <- Sys.readlink(absolute)
      if (!is.na(link) && nzchar(link)) {
        inv_path_fail(
          "release enumeration must not enter symbolic-link components: %s",
          relative
        )
      }
      included <- isTRUE(all_files) || !startsWith(entry, ".")
      if (dir.exists(absolute)) {
        if (included) output <- c(output, walk(relative))
      } else if (included &&
                 (is.null(pattern) || grepl(pattern, entry))) {
        output <- c(output, relative)
      }
    }
    output
  }

  paths <- walk(directory)
  if (length(paths)) {
    inv_assert_safe_relative_paths(
      root, paths, "release enumeration", expected = "file"
    )
  }
  sort(paths, method = "radix")
}
