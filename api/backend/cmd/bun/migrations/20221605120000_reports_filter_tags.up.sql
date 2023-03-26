alter table reports
add column filter_tags text[] null default null check ( filter_tags is null or array_length(filter_tags, 1) > 0 );