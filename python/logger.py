import logging

def setup_logger(log_file, log_level=logging.INFO):
    """
    Set up a logger to write logs to a file.
    
    :param log_file: The path to the log file.
    :param log_level: The log level (default is logging.INFO).
    :return: Configured logger.
    """
    # Define log format
    log_format = '%(asctime)s - %(levelname)s - %(message)s'

    # Configure the logger
    logging.basicConfig(
        filename=log_file,       # Log file path
        level=log_level,         # Log level (e.g., INFO, WARNING, ERROR)
        format=log_format,       # Log format
        filemode='a',
        datefmt='%D-%H:%M:%S'             # File mode (a: append, w: overwrite)
    )

    return logging.getLogger()
