#!/usr/bin/env bash

if [ "$PHP_FPM_USER_ID" != "" ]; then
    (>&2 echo "Warning: PHP_FPM_USER_ID is deprecated. Please use WWW_DATA_USER_ID instead.")
    WWW_DATA_USER_ID=$PHP_FPM_USER_ID
fi

# Set the uid that www-data will run as if one was specified
if [ "$WWW_DATA_USER_ID" != "" ]; then
    usermod -u $WWW_DATA_USER_ID www-data
fi

replace_in_files() {
    PHP_CONFIG_FILES=${1}
    VAR_MATCH=${2}
    REPLACE_VARS=`printenv | awk -F'=' '{print $1}' | grep -E "^$VAR_MATCH"`

    # If there are variables to be replace move forward
    if [ ! -z "$REPLACE_VARS" ]; then
      for VAR_NAME in $REPLACE_VARS; do
        # get the directive name by removing the prefixes e.g. PHP_CLI and making them lowercase.
        # if there are any double '_' replace with a dot.
        DIRECTIVE=`echo "$VAR_NAME" | cut -c9- | tr '[:upper:]' '[:lower:]' | sed 's/__/./g'`
        VALUE=`printenv "$VAR_NAME"`

        # Replace the variable only if it starts with the name of the directive and remove optional ';'
        find $PHP_CONFIG_FILES -type f -exec \
            sed -i "s/^\(;\)\{0,1\}$DIRECTIVE = [^\n]\+/$DIRECTIVE = $VALUE/g" {} \;
      done
    fi
}

# Set php.ini options
for TYPE in cli fpm; do
    PHP_CONFIG_FILES=/etc/php/$PHP_VERSION/$TYPE/
    VAR_TYPE=`echo "PHP_$TYPE" | tr '[:lower:]' '[:upper:]'`

    # Replace all variables ( prefixed by PHP_TYPE ) on the proper PHP type file
    replace_in_files $PHP_CONFIG_FILES $VAR_TYPE

    # Replace all variables ( prefixed by PHP_ALL )
    replace_in_files $PHP_CONFIG_FILES "PHP_ALL"
done

/usr/local/bin/entrypoint.sh "$@"
