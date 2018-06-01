class Post
  def change_title(title)
    changeset = EventChangeset.new
    changeset << Event.new(:title_changed, old_title: @title, new_title: title)
    changeset
  end

  def on_title_changed(event)
    @title = event.payload.new_title
  end
end

params = {
  title: 'Some title'
}

id = '123'

repo = EventRepository.new(adapter)

post = repo.get(Post, id)
changeset = post.change_title(params[:title])
repo.save(Post, changeset)
