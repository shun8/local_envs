DROP TABLE test;
CREATE TABLE test (
	test_id CHAR(5),
	test_ym CHAR(6),
	test_name VARCHAR(20) NOT NULL,
	PRIMARY KEY ( test_id, test_ym )
);
