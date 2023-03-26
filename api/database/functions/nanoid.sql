CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION nanoid (size int DEFAULT 21, alphabet text DEFAULT '_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
    RETURNS text
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    idBuilder text := '';
    i int := 0;
    bytes bytea;
    alphabetIndex int;
    mask int;
    step int;
BEGIN
    mask := (2 << cast(floor(log(length(alphabet) - 1) / log(2)) AS int)) - 1;
    step := cast(ceil(1.6 * mask * size / length(alphabet)) AS int);
    while TRUE LOOP
        bytes := gen_random_bytes(size);
        while i < size LOOP
            alphabetIndex := (get_byte(bytes, i) & mask) + 1;
            IF alphabetIndex <= length(alphabet) THEN
                idBuilder := idBuilder || substr(alphabet, alphabetIndex, 1);
                IF length(idBuilder) = size THEN
                    RETURN idBuilder;
                END IF;
            END IF;
            i = i + 1;
        END LOOP;
        i := 0;
    END LOOP;
END
$$;

