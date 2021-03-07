DROP TABLE h_0;
CREATE TABLE h_0 (
	id CHAR(5),
	ym CHAR(6),
	h_txt NVARCHAR(20) NOT NULL,
    t_value INTEGER,
    h_order INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE h_1;
CREATE TABLE h_1 (
	id CHAR(5),
	ym CHAR(6),
	h_txt NVARCHAR(20) NOT NULL,
    t_value INTEGER,
    h_order INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE h_2;
CREATE TABLE h_2 (
	id CHAR(5),
	ym CHAR(6),
	h_txt NVARCHAR(20) NOT NULL,
    t_value INTEGER,
    h_order INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE h_3;
CREATE TABLE h_3 (
	id CHAR(5),
	ym CHAR(6),
	h_txt NVARCHAR(20) NOT NULL,
    t_value INTEGER,
    h_order INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE h_4;
CREATE TABLE h_4 (
	id CHAR(5),
	ym CHAR(6),
	h_txt NVARCHAR(20) NOT NULL,
    t_value INTEGER,
    h_order INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE t_0;
CREATE TABLE t_0 (
	id CHAR(5),
	ym CHAR(6),
	h0_txt NVARCHAR(20) NOT NULL,
	h1_txt NVARCHAR(20) NOT NULL,
    h2_txt NVARCHAR(20) NOT NULL,    
    t_value INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE t_1;
CREATE TABLE t_1 (
	id CHAR(5),
	ym CHAR(6),
	h0_txt NVARCHAR(20) NOT NULL,
	h1_txt NVARCHAR(20) NOT NULL,
    h2_txt NVARCHAR(20) NOT NULL,    
    t_value INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE t_2;
CREATE TABLE t_2 (
	id CHAR(5),
	ym CHAR(6),
	h0_txt NVARCHAR(20) NOT NULL,
	h1_txt NVARCHAR(20) NOT NULL,
    h2_txt NVARCHAR(20) NOT NULL,    
    t_value INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE t_3;
CREATE TABLE t_3 (
	id CHAR(5),
	ym CHAR(6),
	h0_txt NVARCHAR(20) NOT NULL,
	h1_txt NVARCHAR(20) NOT NULL,
    h2_txt NVARCHAR(20) NOT NULL,    
    t_value INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);

DROP TABLE t_4;
CREATE TABLE t_4 (
	id CHAR(5),
	ym CHAR(6),
	h0_txt NVARCHAR(20) NOT NULL,
	h1_txt NVARCHAR(20) NOT NULL,
    h2_txt NVARCHAR(20) NOT NULL,    
    t_value INTEGER NOT NULL,
	PRIMARY KEY ( id, ym )
);
