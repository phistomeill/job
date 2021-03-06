class Topic < ActiveRecord::Base
  has_many :topic_tags
  has_many :tags, :through => :topic_tags
  belongs_to :parent, :class_name => 'Topic'
  has_many :children, :class_name => 'Topic', :foreign_key => :parent_id

  # default_scope -> { order('manual_salary DESC, analyzed_release_at DESC') }
  #default_scope -> { order('analyzed_salary DESC') }
  default_scope -> { order('analyzed_release_at DESC') }

  scope :master, -> { where('parent_id is null') }

  def self.merge(ids)
    topic_list = self.where(id: ids).order('analyzed_release_at DESC')
    if topic_list.count < 2
      return topic_list.first
    end

    parent = topic_list.first
    topic_list.each do |topic|
      if topic == parent
        topic.parent = nil
      else
        topic.parent = parent
      end
      topic.save!
    end
    return parent
  end

  def is_child
    self.parent != nil
  end

  def self.search(key)
    if key.blank?
      return []
    end

    condition = ""
    params = []

    columns = %w(title analyzed_salary analyzed_author analyzed_company manual_salary manual_memo manual_company)
    columns.each do |column|
      condition += " OR " unless condition.blank?
      condition += "#{column} LIKE ?"
      params << "%#{key}%"
    end

    return self.where(condition, *params)
  end

  def analyzed_author_url
    "http://ruby-china.org/#{self.analyzed_author}"
  end

  def analyzed_release_at_text
    if analyzed_release_at
      return analyzed_release_at.strftime("%Y-%m-%d")
    else
      return "无"
    end
  end

  def is_taged(tag)
    self.topic_tags.exists?(tag_id: tag.id)
  end

  def add_tag(tag_name)
    tag = Tag.find_by_name(tag_name)
    unless tag
      tag = Tag.create!(name: tag_name)
    end

    topic = self
    topic_tag = {topic_id: topic.id, tag_id: tag.id}

    if TopicTag.exists?(topic_tag)
      return
    end

    TopicTag.create!(topic_tag)
  end

  def remove_tag(tag_name)
    tag = Tag.find_by_name(tag_name)
    unless tag
      return
    end

    topic_tag = self.topic_tags.find_by_tag_id(tag.id)
    unless topic_tag
      return
    end

    topic_tag.destroy!
  end

  def tag_name
    list = self.tags.collect do |t|
      t.name
    end
    list.join(' ')
  end

end
