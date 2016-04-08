#!/usr/bin/bash
# wrapper for sending emails through curl easily
# curl command is from https://stackoverflow.com/questions/14722556/using-curl-to-send-email/16069786#16069786
########## config

# csv of smtp servers of email providers that will be automatically detected.
# i don't own accounts on most of these so i can't confirm if they work or not.
# contributions are greatly appreciated!
smtp_server_list="\
MATCH,SERVER
gmail.com,smtps://smtp.gmail.com:465
icloud.com,smtps://smtp.mail.me.com:587
mail.ru,smtps://smtp.mail.ru:465
openmailbox.org,smtps://smtp.openmailbox.org:465
outlook.com,smtp://smtp-mail.outlook.com:587
yahoo.com,smtps://smtp.mail.yahoo.com:465
"

########## defaults

body_file=
from_address=
from_name=
password=
to_address=
to_name=
smtp_server=
subject="none"

########## parse options

this=$(basename "$0")

function usage() {
    cat <<EOF
usage: $this [-h] [-b body_file] [-e editor] [-f from_address] [-F from_name]
       [-m mail_file] [-p password] [-t to_address] [-S subject] [-T to_name]
       -b body_file       use the contents of the specified plaintext body_file
                          as the body of the message. if this is specified,
                          then the email will be sent without opening a text
                          editor to allow you to edit it.
       -e editor          use the specified editor to write mail (default is the
                          value of the \$EDITOR variable)
       -f from_address    account that email is being sent from
       -F from_name       name to be displayed in the From: field (default is
                          the username of the specified account)
       -h                 display this message and exit
       -p password        **DANGEROUS OPTION** use the given password to log in
                          to the from_address account
       -s smtp_server     use the specified smtp server. the format should be as
                          follows: smtp://domain.tld:port. some of the most
                          common email providers are automatically detected
       -S subject         specify the subject string (default: "none")
       -t to_address      name to be displayed in the To: field (default is the
                          username of the specified account)
       -T to_name         account that email is being sent to

this script will open an email template in the specified text editor. write your
email, make any changes if needed, save, and exit to send the email.

be very wary of including your password in scripts and even warier of doing it
in plaintext. also note that people near you will be able to see your password
if you're typing it out.

EOF
}

while getopts ":b:e:f:F:hps:S:t:T:" opt; do
    case $opt in
        b) if [ -f "$OPTARG" ]; then
               body_file="$OPTARG"
           else
               echo "error: $OPTARG is not a valid file"
           fi
           ;;
        e) EDITOR="$OPTARG" ;;
        f) from_address="$OPTARG" ;;
        F) from_name="$OPTARG" ;;
        h) usage; exit 0 ;;
        p) password="$OPTARG" ;;
        s) smtp_server="$OPTARG" ;;
        S) subject="$OPTARG" ;;
        t) to_address="$OPTARG" ;;
        T) to_name="$OPTARG" ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## fill in blank variables

# prefer terminal-based editors and lighter gui editors
if [ -z "$EDITOR" ] && [ -z "$body_file" ]; then
    EDITOR=$(\
        command -v vim || \
        command -v emacs || \
        command -v nano || \
        command -v acme || \
        command -v mousepad || \
        command -v gedit || \
        command -v kate \
        )
    if [ -z "$EDITOR" ]; then
        echo "error: no usable editor found. please specify one with"
        echo "$this -e. see $this -h for more info."
        exit 1
    fi
fi

if [ -z "$from_address" ]; then
    echo "no from_address specified. please enter one below:"
    read from_address
fi
if [ -z "$to_address" ]; then
    echo "no to_address specified. please enter one below:"
    read to_address
fi

if [ -z "$from_name" ]; then
    from_name=$(cut -d "@" -f 1 <<< "$from_address")
fi
if [ -z "$to_name" ]; then
    to_name=$(cut -d "@" -f 1 <<< "$to_address")
fi

if [ -z "$smtp_server" ]; then
    smtp_server=$(grep $(cut -d "@" -f 2 <<< "$from_address") \
        <<< "$smtp_server_list" | cut -d "," -f 2)
    if [ -z "$smtp_server" ]; then
        echo "could not determine smtp server; please enter one below."
        echo "use the following format: smtps://domain.tld:port"
        read smtp_server
    fi
fi

########## email

mail_tmp=$(mktemp -u /tmp/email-XXXXX)

cat <<EOF > $mail_tmp
From: "$from_name" <$from_address>
To: "$to_name" <$to_address>
Subject: $subject


EOF

trap "rm -f $mail_tmp; stty sane" SIGINT SIGTERM
if [ -z "$body_file" ]; then
    $EDITOR $mail_tmp
else
    mail_tmp_intermediate=$(mktemp -u /tmp/email-XXXXX)
    head -n 4 $mail_tmp > $mail_tmp_intermediate
    cat $mail_tmp_intermediate "$body_file" > $mail_tmp
    rm $mail_tmp_intermediate
fi

curl \
    --url "$smtp_server" --ssl-reqd \
    --user "$from_address$(! [ -z "$password" ] && echo ":$password")" \
    --mail-from "$from_address" \
    --mail-rcpt "$to_address" \
    --upload-file $mail_tmp

rm -f $mail_tmp
