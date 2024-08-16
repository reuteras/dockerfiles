# Basics
Set($rtname, 'rt.example.com');
Set($Organization, 'example.me');
Set($Timezone, 'Europe/Stockholm');
Set($OwnerEmail, 'owner@example.com');
Set($CorrespondAddress , 'rt@example.me');
Set($CommentAddress , 'rt-comment@example.me');

# Web
Set($WebPort, 443);
Set($WebPath , "");
Set($WebBaseURL , "https://rt.example.com");
Set($WebURL , "https://rt.example.com/");
Set($WebDomain , "rt.example.com");
Set($CanonicalizeRedirectURLs, 1);

# Database
my %typemap = (
    mysql   => 'mysql',
    pgsql   => 'Pg',
    sqlite3 => 'SQLite',
);
Set($DatabaseType, $typemap{pgsql} || "UNKNOWN");
# SQLite needs a special case, since $DatabaseName must be a full pathname
my $dbc_dbname = 'rtdb'; if ( "pgsql" eq "sqlite3" ) { Set ($DatabaseName, '' . '/' . $dbc_dbname); } else { Set ($DatabaseName, $dbc_dbname); }
Set($DatabaseHost, 'RT_DB_HOST');
Set($DatabasePort, 'RT_DB_PORT');
Set($DatabaseUser , 'RT_DB_USER');
Set($DatabasePassword , 'RT_DB_PASS');

# Misc
Set($LogToSyslog, "info");
Set( %FullTextSearch,
    Enable     => 1,
    Indexed    => 1,
    Column     => 'ContentIndex',
    Table      => 'Attachments',
);
Set(%GnuPG,
    Enable                 => 0,
    GnuPG                  => '/usr/bin/gpg',
    Passphrase             => undef,
    OutgoingMessagesFormat => "RFC", # Inline
);
Plugin('RT::Extension::TerminalTheme');
Plugin('RT::IR');

1;
