#' Transform data
#' @description These layout functions are not layout in the network diagram,
#' it just converts the original data into a form that makes it easy to draw
#' a curve graph.
#' @param data a data frame.
#' @param start.var,end.var character to specify which variable is the starting
#' points and which is the ending points. if the variable is not character, it
#' is forced to be converted.
#' @param horiz a logical value. If FALSE, the parallel graph are drawn vertically.
#' If TRUE, the parallel graph are drawn horizontally.
#' @param sort.start,sort.end charater vector, the nodes will be sorted by this parameter.
#' @param start.x,start.y,end.x,end.y numeric to specify the x (horiz = TRUE) or y
#' (horiz = FALSE) coordinates.
#' @param type the type (""upper" or "lower") of the correlation matrix plot.
#' @param show.diag a logical value indicating whether keep the diagonal.
#' @param row.names,col.names row/column names of correlation matrix.
#' @param cor_tbl a col_tbl object.
#' @return a data frame.
#' @importFrom rlang enquo eval_tidy set_names quo_is_null
#' @importFrom dplyr filter
#' @rdname create-layout
#' @examples
#' cor_tbl(cor(mtcars)) %>%
#'   parallel_layout()
#' \dontrun{
#' data("varespec", package = "vegan")
#' data("varechem", package = "vegan")
#' mantel_test(varespec, varechem) %>%
#'   combination_layout(type = "upper", col.names = colnames(varechem),
#'                      show.diag = FALSE)
#' }
#' @author Houyun Huang, Lei Zhou, Jian Chen, Taiyun Wei
#' @export
parallel_layout <- function(data,
                            start.var = NULL,
                            end.var = NULL,
                            horiz = FALSE,
                            sort.start = NULL,
                            sort.end = NULL,
                            start.x = NULL,
                            start.y = NULL,
                            end.x = NULL,
                            end.y = NULL)
{
  if(!is.data.frame(data))
    data <- as.data.frame(data)
  start <- if(rlang::quo_is_null(enquo(start.var))) {
    data[[1]]
  } else {
    rlang::eval_tidy(rlang::enquo(start.var), data)
  }
  end <- if(rlang::quo_is_null(enquo(end.var))) {
    data[[2]]
  } else {
    rlang::eval_tidy(rlang::enquo(end.var), data)
  }
  if(!is.character(start))
    start <- as.character(start)
  if(!is.character(end))
    end <- as.character(end)

  unique.start <- unique(start[!is.na(start)])
  unique.end <- unique(end[!is.na(end)])
  n <- max(length(unique.start), length(unique.end))
  if(!is.null(sort.start) && length(sort.start) != length(unique.start)) {
    stop("Length of 'sort.start' and unique elements of 'start' don't match.",
          call. = FALSE)
  }
  if(!is.null(sort.end) && length(sort.end) != length(unique.end)) {
    stop("Length of 'sort.end' and unique elements of 'end' don't match.",
          call. = FALSE)
  }
  start.pos <- if(is.null(sort.start)) {
    rlang::set_names(seq(n, 1, length.out = length(unique.start)), unique.start)
  } else {
    rlang::set_names(seq(length(sort.start), 1), sort.start)
  }
  end.pos <- if(is.null(sort.start)) {
    rlang::set_names(seq(n, 1, length.out = length(unique.end)), unique.end)
  } else {
    rlang::set_names(seq(length(sort.end), 1), sort.end)
  }
  pos <- if(horiz) {
    tibble::tibble(x = start.pos[start], y = start.y %||% 0, xend = end.pos[end],
                   yend = end.y %||% 1, start.label = start, end.label = end,
                   .start.filter = !duplicated(start) & !is.na(start),
                   .end.filter = !duplicated(end) & !is.na(end))
  } else {
    tibble::tibble(x = start.x %||% 0, y = start.pos[start], xend = end.x %||% 1,
                   yend = end.pos[end], start.label = start, end.label = end,
                   .start.filter = !duplicated(start) & !is.na(start),
                   .end.filter = !duplicated(end) & !is.na(end))
  }
  structure(.Data = dplyr::bind_cols(pos, data),
            class = c("layout_link_tbl", class(pos)))
}

#' @rdname create-layout
#' @export
combination_layout <- function(data,
                               type = NULL,
                               show.diag = NULL,
                               row.names = NULL,
                               col.names = NULL,
                               start.var = NULL,
                               end.var = NULL,
                               cor_tbl)
{
  non.cor.tbl <- missing(cor_tbl)
  if(!non.cor.tbl) {
    if(!is_cor_tbl(cor_tbl) || !is_symmet(cor_tbl))
      stop("Need a symmetric cor_tbl.", call. = FALSE)
  }
  row.names <- if(non.cor.tbl) {
    rev(row.names) %||% col.names
  } else {
    rev(get_row_name(cor_tbl))
  }
  type <- if(non.cor.tbl) type else get_type(cor_tbl)
  show.diag <- if(non.cor.tbl) show.diag else get_show_diag(cor_tbl)
  start <- if(rlang::quo_is_null(enquo(start.var))) {
    data[[1]]
  } else {
    rlang::eval_tidy(rlang::enquo(start.var), data)
  }
  end <- if(rlang::quo_is_null(enquo(end.var))) {
    data[[2]]
  } else {
    rlang::eval_tidy(rlang::enquo(end.var), data)
  }
  if(!is.character(start))
    start <- as.character(start)
  if(!is.character(end))
    end <- as.character(end)

  spec.name <- unique(start[!is.na(start)])
  n <- length(row.names)
  m <- length(spec.name)
  ## get position of spec point
  if(type == "full") {
    stop("The 'type' of cor_tbl is not supported.", call. = FALSE)
  }

  if(type == "upper") {
    if(m == 1) {
      x <- 0.5 + 0.18 * n
      y <- 0.5 + 0.3 * n
    } else if(m == 2) {
      x <- c(0.5 - 0.02 * n, 0.5 + 0.2 * n)
      y <- c(0.5 + 0.46 * n, 0.5 + 0.2 * n)
    } else {
      y <- seq(0.5 + n * (1 - 0.3), 0.5 + n * 0.1, length.out = m)
      x <- seq(0.5 - 0.25 * n, 0.5 + 0.3 * n, length.out = m)
    }
  } else if(type == "lower") {
    if(m == 1) {
      x <- 0.5 + 0.82 * n
      y <- 0.5 + 0.7 * n
    } else if(m == 2) {
      x <- c(0.5 + 0.8 * n, 0.5 + 1.02 * n)
      y <- c(0.5 + 0.8 * n, 0.5 + 0.54 * n)
    } else {
      y <- seq(0.5 + n * (1 - 0.1), 0.5 + n * 0.3, length.out = m)
      x <- seq(0.5 + 0.75 * n, 0.5 + 1.3 * n, length.out = m)
    }
  }
  x <- rlang::set_names(x, spec.name)
  y <- rlang::set_names(y, spec.name)

  ## get position of env point
  xend <- n:1
  yend <- 1:n
  if(type == "upper") {
    if(show.diag) {
      xend <- xend - 2
    } else {
      xend <- xend - 1
    }
  } else {
    if(show.diag) {
      xend <- xend + 2
    } else {
      xend <- xend + 1
    }
  }
  xend <- rlang::set_names(xend, row.names)
  yend <- rlang::set_names(yend, row.names)

  ## bind postion end data
  pos <- tibble::tibble(x = x[start], y = y[start],
                        xend = xend[end], yend = yend[end],
                        start.label = start, end.label = end,
                        .start.filter = !duplicated(start) & !is.na(start),
                        .end.filter = !duplicated(end) & !is.na(end))
  structure(.Data = dplyr::bind_cols(pos, data),
            class = c("layout_link_tbl", class(pos)))
}
