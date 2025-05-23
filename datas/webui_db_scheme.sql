--
-- Fichier généré par SQLiteStudio v3.3.3 sur lun. avr. 28 17:35:32 2025
--
-- Encodage texte utilisé : UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table : alembic_version
CREATE TABLE alembic_version (
    version_num VARCHAR (32) NOT NULL,
    CONSTRAINT alembic_version_pkc PRIMARY KEY (
        version_num
    )
);


-- Table : auth
CREATE TABLE auth (
    id       VARCHAR (255) NOT NULL,
    email    VARCHAR (255) NOT NULL,
    password TEXT          NOT NULL
                           NOT NULL,
    active   INTEGER       NOT NULL
);


-- Table : channel
CREATE TABLE channel (
    id             TEXT   NOT NULL,
    user_id        TEXT,
    name           TEXT,
    description    TEXT,
    data           JSON,
    meta           JSON,
    access_control JSON,
    created_at     BIGINT,
    updated_at     BIGINT,
    type           TEXT,
    PRIMARY KEY (
        id
    ),
    UNIQUE (
        id
    )
);


-- Table : channel_member
CREATE TABLE channel_member (
    id         TEXT   NOT NULL,
    channel_id TEXT   NOT NULL,
    user_id    TEXT   NOT NULL,
    created_at BIGINT,
    PRIMARY KEY (
        id
    ),
    UNIQUE (
        id
    )
);


-- Table : chat
CREATE TABLE chat (
    id         VARCHAR (255) NOT NULL,
    user_id    VARCHAR (255) NOT NULL,
    title      TEXT          NOT NULL
                             NOT NULL,
    share_id   VARCHAR (255),
    archived   INTEGER       NOT NULL,
    created_at DATETIME      NOT NULL
                             NOT NULL,
    updated_at DATETIME      NOT NULL
                             NOT NULL,
    chat       JSON,
    pinned     BOOLEAN,
    meta       JSON          DEFAULT '{}'
                             NOT NULL,
    folder_id  TEXT
);


-- Table : chatidtag
CREATE TABLE chatidtag (
    id        VARCHAR (255) NOT NULL,
    tag_name  VARCHAR (255) NOT NULL,
    chat_id   VARCHAR (255) NOT NULL,
    user_id   VARCHAR (255) NOT NULL,
    timestamp INTEGER       NOT NULL
                            NOT NULL
);


-- Table : config
CREATE TABLE config (
    id         INTEGER  NOT NULL,
    data       JSON     NOT NULL,
    version    INTEGER  NOT NULL,
    created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) 
                        NOT NULL,
    updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP),
    PRIMARY KEY (
        id
    )
);


-- Table : document
CREATE TABLE document (
    id              INTEGER       NOT NULL
                                  PRIMARY KEY,
    collection_name VARCHAR (255) NOT NULL,
    name            VARCHAR (255) NOT NULL,
    title           TEXT          NOT NULL
                                  NOT NULL,
    filename        TEXT          NOT NULL
                                  NOT NULL,
    content         TEXT,
    user_id         VARCHAR (255) NOT NULL,
    timestamp       INTEGER       NOT NULL
                                  NOT NULL
);


-- Table : feedback
CREATE TABLE feedback (
    id         TEXT   NOT NULL,
    user_id    TEXT,
    version    BIGINT,
    type       TEXT,
    data       JSON,
    meta       JSON,
    snapshot   JSON,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY (
        id
    )
);


-- Table : file
CREATE TABLE file (
    id             TEXT    NOT NULL,
    user_id        TEXT    NOT NULL,
    filename       TEXT    NOT NULL,
    meta           JSON,
    created_at     INTEGER NOT NULL,
    hash           TEXT,
    data           JSON,
    updated_at     BIGINT,
    path           TEXT,
    access_control JSON
);


-- Table : folder
CREATE TABLE folder (
    id          TEXT    NOT NULL,
    parent_id   TEXT,
    user_id     TEXT    NOT NULL,
    name        TEXT    NOT NULL,
    items       JSON,
    meta        JSON,
    is_expanded BOOLEAN NOT NULL,
    created_at  BIGINT  NOT NULL,
    updated_at  BIGINT  NOT NULL,
    PRIMARY KEY (
        id,
        user_id
    )
);


-- Table : function
CREATE TABLE function (
    id         TEXT    NOT NULL,
    user_id    TEXT    NOT NULL,
    name       TEXT    NOT NULL,
    type       TEXT    NOT NULL,
    content    TEXT    NOT NULL,
    meta       TEXT    NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    valves     TEXT,
    is_active  INTEGER NOT NULL,
    is_global  INTEGER NOT NULL
);


-- Table : group
CREATE TABLE [group] (
    id          TEXT   NOT NULL,
    user_id     TEXT,
    name        TEXT,
    description TEXT,
    data        JSON,
    meta        JSON,
    permissions JSON,
    user_ids    JSON,
    created_at  BIGINT,
    updated_at  BIGINT,
    PRIMARY KEY (
        id
    ),
    UNIQUE (
        id
    )
);


-- Table : knowledge
CREATE TABLE knowledge (
    id             TEXT   NOT NULL,
    user_id        TEXT   NOT NULL,
    name           TEXT   NOT NULL,
    description    TEXT,
    data           JSON,
    meta           JSON,
    created_at     BIGINT NOT NULL,
    updated_at     BIGINT,
    access_control JSON,
    PRIMARY KEY (
        id
    )
);


-- Table : memory
CREATE TABLE memory (
    id         VARCHAR (255) NOT NULL,
    user_id    VARCHAR (255) NOT NULL,
    content    TEXT          NOT NULL,
    updated_at INTEGER       NOT NULL,
    created_at INTEGER       NOT NULL
);


-- Table : message
CREATE TABLE message (
    id         TEXT   NOT NULL,
    user_id    TEXT,
    channel_id TEXT,
    content    TEXT,
    data       JSON,
    meta       JSON,
    created_at BIGINT,
    updated_at BIGINT,
    parent_id  TEXT,
    PRIMARY KEY (
        id
    ),
    UNIQUE (
        id
    )
);


-- Table : message_reaction
CREATE TABLE message_reaction (
    id         TEXT   NOT NULL,
    user_id    TEXT   NOT NULL,
    message_id TEXT   NOT NULL,
    name       TEXT   NOT NULL,
    created_at BIGINT,
    PRIMARY KEY (
        id
    ),
    UNIQUE (
        id
    )
);


-- Table : migratehistory
CREATE TABLE migratehistory (
    id          INTEGER       NOT NULL
                              PRIMARY KEY,
    name        VARCHAR (255) NOT NULL,
    migrated_at DATETIME      NOT NULL
);


-- Table : model
CREATE TABLE model (
    id             TEXT    NOT NULL,
    user_id        TEXT    NOT NULL,
    base_model_id  TEXT,
    name           TEXT    NOT NULL,
    meta           TEXT    NOT NULL,
    params         TEXT    NOT NULL,
    created_at     INTEGER NOT NULL,
    updated_at     INTEGER NOT NULL,
    access_control JSON,
    is_active      BOOLEAN DEFAULT (1) 
                           NOT NULL
);


-- Table : prompt
CREATE TABLE prompt (
    id             INTEGER       NOT NULL
                                 PRIMARY KEY,
    command        VARCHAR (255) NOT NULL,
    user_id        VARCHAR (255) NOT NULL,
    title          TEXT          NOT NULL
                                 NOT NULL,
    content        TEXT          NOT NULL,
    timestamp      INTEGER       NOT NULL
                                 NOT NULL,
    access_control JSON
);


-- Table : tag
CREATE TABLE tag (
    id      VARCHAR (255) NOT NULL,
    name    VARCHAR (255) NOT NULL,
    user_id VARCHAR (255) NOT NULL,
    meta    JSON,
    CONSTRAINT pk_id_user_id PRIMARY KEY (
        id,
        user_id
    )
);


-- Table : tool
CREATE TABLE tool (
    id             TEXT    NOT NULL,
    user_id        TEXT    NOT NULL,
    name           TEXT    NOT NULL,
    content        TEXT    NOT NULL,
    specs          TEXT    NOT NULL,
    meta           TEXT    NOT NULL,
    created_at     INTEGER NOT NULL,
    updated_at     INTEGER NOT NULL,
    valves         TEXT,
    access_control JSON
);


-- Table : user
CREATE TABLE user (
    id                VARCHAR (255) NOT NULL,
    name              VARCHAR (255) NOT NULL,
    email             VARCHAR (255) NOT NULL,
    role              VARCHAR (255) NOT NULL,
    profile_image_url TEXT          NOT NULL
                                    NOT NULL,
    api_key           VARCHAR (255),
    created_at        INTEGER       NOT NULL
                                    NOT NULL,
    updated_at        INTEGER       NOT NULL
                                    NOT NULL,
    last_active_at    INTEGER       NOT NULL
                                    NOT NULL,
    settings          TEXT,
    info              TEXT,
    oauth_sub         TEXT
);


-- Index : auth_id
CREATE UNIQUE INDEX auth_id ON auth (
    "id"
);


-- Index : chat_id
CREATE UNIQUE INDEX chat_id ON chat (
    "id"
);


-- Index : chat_share_id
CREATE UNIQUE INDEX chat_share_id ON chat (
    "share_id"
);


-- Index : chatidtag_id
CREATE UNIQUE INDEX chatidtag_id ON chatidtag (
    "id"
);


-- Index : document_collection_name
CREATE UNIQUE INDEX document_collection_name ON document (
    "collection_name"
);


-- Index : document_name
CREATE UNIQUE INDEX document_name ON document (
    "name"
);


-- Index : file_id
CREATE UNIQUE INDEX file_id ON file (
    id
);


-- Index : function_id
CREATE UNIQUE INDEX function_id ON function (
    "id"
);


-- Index : memory_id
CREATE UNIQUE INDEX memory_id ON memory (
    "id"
);


-- Index : model_id
CREATE UNIQUE INDEX model_id ON model (
    "id"
);


-- Index : prompt_command
CREATE UNIQUE INDEX prompt_command ON prompt (
    "command"
);


-- Index : tool_id
CREATE UNIQUE INDEX tool_id ON tool (
    "id"
);


-- Index : user_api_key
CREATE UNIQUE INDEX user_api_key ON user (
    "api_key"
);


-- Index : user_id
CREATE UNIQUE INDEX user_id ON user (
    "id"
);


-- Index : user_oauth_sub
CREATE UNIQUE INDEX user_oauth_sub ON user (
    "oauth_sub"
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
