
-- DROP TABLES IF EXISTS (in reverse order of dependencies)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE lib_Loans';
    EXECUTE IMMEDIATE 'DROP TABLE lib_Books';
    EXECUTE IMMEDIATE 'DROP TABLE lib_Members';
    EXECUTE IMMEDIATE 'DROP TABLE lib_Authors';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Step 1: Create Authors Table
CREATE TABLE lib_Authors (
    author_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    birth_year NUMBER(4)
);

-- Step 2: Create Authors Sequence and Trigger
CREATE SEQUENCE lib_authors_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER lib_authors_before_insert
BEFORE INSERT ON lib_Authors
FOR EACH ROW
BEGIN
    IF :NEW.author_id IS NULL THEN
        SELECT lib_authors_seq.NEXTVAL INTO :NEW.author_id FROM dual;
    END IF;
END;
/

-- Step 3: Create Books Table
CREATE TABLE lib_Books (
    book_id NUMBER PRIMARY KEY,
    title VARCHAR2(100) NOT NULL,
    author_id NUMBER NOT NULL,
    published_year NUMBER(4),
    genre VARCHAR2(30),
    CONSTRAINT fk_books_authors FOREIGN KEY (author_id) REFERENCES lib_Authors(author_id)
);

-- Step 4: Create Books Sequence and Trigger
CREATE SEQUENCE lib_books_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER lib_books_before_insert
BEFORE INSERT ON lib_Books
FOR EACH ROW
BEGIN
    IF :NEW.book_id IS NULL THEN
        SELECT lib_books_seq.NEXTVAL INTO :NEW.book_id FROM dual;
    END IF;
END;
/

-- Step 5: Create Members Table
CREATE TABLE lib_Members (
    member_id NUMBER PRIMARY KEY,
    full_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    joined_date DATE DEFAULT SYSDATE
);

-- Step 6: Create Members Sequence and Trigger
CREATE SEQUENCE lib_members_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER lib_members_before_insert
BEFORE INSERT ON lib_Members
FOR EACH ROW
BEGIN
    IF :NEW.member_id IS NULL THEN
        SELECT lib_members_seq.NEXTVAL INTO :NEW.member_id FROM dual;
    END IF;
END;
/

-- Step 7: Create Loans Table
CREATE TABLE lib_Loans (
    loan_id NUMBER PRIMARY KEY,
    member_id NUMBER NOT NULL,
    book_id NUMBER NOT NULL,
    loan_date DATE DEFAULT SYSDATE,
    return_date DATE,
    CONSTRAINT fk_loan_members FOREIGN KEY (member_id) REFERENCES lib_Members(member_id),
    CONSTRAINT fk_loan_books FOREIGN KEY (book_id) REFERENCES lib_Books(book_id)
);

-- Step 8: Create Loans Sequence and Trigger
CREATE SEQUENCE lib_loans_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER lib_loans_before_insert
BEFORE INSERT ON lib_Loans
FOR EACH ROW
BEGIN
    IF :NEW.loan_id IS NULL THEN
        SELECT lib_loans_seq.NEXTVAL INTO :NEW.loan_id FROM dual;
    END IF;
END;
/

-- Step 9: Insert Sample Data
INSERT INTO lib_Authors (first_name, last_name, birth_year) VALUES ('George', 'Orwell', 1903);
INSERT INTO lib_Authors (first_name, last_name, birth_year) VALUES ('Jane', 'Austen', 1775);
INSERT INTO lib_Authors (first_name, last_name, birth_year) VALUES ('Mark', 'Twain', 1835);

INSERT INTO lib_Books (title, author_id, published_year, genre) VALUES ('1984', 1, 1949, 'Dystopian');
INSERT INTO lib_Books (title, author_id, published_year, genre) VALUES ('Pride and Prejudice', 2, 1813, 'Romance');
INSERT INTO lib_Books (title, author_id, published_year, genre) VALUES ('Adventures of Huckleberry Finn', 3, 1884, 'Adventure');

INSERT INTO lib_Members (full_name, email) VALUES ('Alice Johnson', 'alice@example.com');
INSERT INTO lib_Members (full_name, email) VALUES ('Bob Smith', 'bob@example.com');

INSERT INTO lib_Loans (member_id, book_id, loan_date, return_date) VALUES (1, 1, TO_DATE('2025-04-01','YYYY-MM-DD'), TO_DATE('2025-04-15','YYYY-MM-DD'));
INSERT INTO lib_Loans (member_id, book_id, loan_date, return_date) VALUES (2, 2, TO_DATE('2025-04-05','YYYY-MM-DD'), NULL);
INSERT INTO lib_Loans (member_id, book_id, loan_date, return_date) VALUES (1, 3, TO_DATE('2025-04-10','YYYY-MM-DD'), NULL);

-- Step 10: Create Views
CREATE OR REPLACE VIEW vw_books_with_authors AS
SELECT b.book_id, b.title, a.first_name || ' ' || a.last_name AS author, b.genre, b.published_year
FROM lib_Books b
JOIN lib_Authors a ON b.author_id = a.author_id;

CREATE OR REPLACE VIEW vw_current_loans AS
SELECT l.loan_id, m.full_name, b.title, l.loan_date, l.return_date
FROM lib_Loans l
JOIN lib_Members m ON l.member_id = m.member_id
JOIN lib_Books b ON l.book_id = b.book_id
WHERE l.return_date IS NULL;

CREATE OR REPLACE VIEW vw_books_borrow_count AS
SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM lib_Books b
LEFT JOIN lib_Loans l ON b.book_id = l.book_id
GROUP BY b.title;

CREATE OR REPLACE VIEW vw_members_loan_summary AS
SELECT m.full_name, COUNT(l.loan_id) AS total_loans
FROM lib_Members m
LEFT JOIN lib_Loans l ON m.member_id = l.member_id
GROUP BY m.full_name;
