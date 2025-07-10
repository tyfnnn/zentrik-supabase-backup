create policy "Avatars are publicly accessible"
on "storage"."objects"
as permissive
for select
to public
using ((bucket_id = 'avatars'::text));


create policy "Users can delete their own avatars"
on "storage"."objects"
as permissive
for delete
to public
using (((bucket_id = 'avatars'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));


create policy "Users can update their own avatars"
on "storage"."objects"
as permissive
for update
to public
using (((bucket_id = 'avatars'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));


create policy "Users can upload their own avatars"
on "storage"."objects"
as permissive
for insert
to public
with check (((bucket_id = 'avatars'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



