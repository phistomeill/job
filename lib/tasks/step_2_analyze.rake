
desc "Step 2 analyze"
task :step_2_analyze => :environment do
  puts "Step 2 analyze"
  Topic.all.each do |topic|
    print "."
    analyze_topic topic
  end
  puts "."
end

def analyze_topic(topic)
  topic = Topic.find_by_url!(topic.url)
  doc = Nokogiri::HTML(open(topic.file))
  description = get_doc_description(doc)
  topic.analyzed_salary = analyze_salary(topic, description)
  topic.analyzed_author = analyze_author(topic, doc)
  topic.analyzed_release_at = analyze_release_at(topic, doc)
  topic.analyzed_company = analyze_company(topic, description)
  topic.save!
end

def analyze_salary(topic, description)
  return topic.analyzed_salary if topic.analyzed_salary

  %w(工资 薪水 年薪 月薪 薪资 待遇 薪酬 Salary).each do |keyword|
    salary = /#{keyword}.{1,50}/.match(description)
    if salary
      return salary.to_s
    end
  end

  return ""
end

def analyze_author(topic, doc)
  return topic.analyzed_author if topic.analyzed_author

  #<a data-author="true" data-name="isofttalent" href="/isofttalent">isofttalent</a>
  element = doc.css('.topic .infos .info a')[1]
  author = element.content.to_s
  return author
end

def analyze_release_at(topic, doc)
  return topic.analyzed_release_at if topic.analyzed_release_at

  #<abbr class="timeago" title="2013-12-01T11:52:51+08:00">9天前</abbr>发布
  element = doc.css('.topic .infos .info abbr.timeago').first
  release_at = element[:title].to_s
  return release_at
end

def analyze_company(topic, description)
  return topic.analyzed_company if topic.analyzed_company

  company = nil
  company ||= analyze_company_1(topic.title)
  company ||= analyze_company_2(description)
  company ||= analyze_company_3(topic.title)

  return company
end

def analyze_company_1(text)
  #[北京]北京圣天博科技有限公司招.....

  %w(公司 团队).each do |keyword|
    result = /\[.*\](.{1,50}#{keyword})/.match(text)
    return result[1] if result
  end
  return nil
end

def analyze_company_2(text)
  #...北京圣天博科技有限公司招.....

  %w(公司 团队).each do |keyword|
    result = /(.{1,50}#{keyword})/.match(text)
    return result[1] if result
  end
  return nil
end

def analyze_company_3(text)
  #[北京]北京圣天博科技 招聘 rails 工程师

  %w(招募 招聘 诚聘 寻找 招 聘 寻).each do |keyword|
    result = /\[.*\](.{1,50})#{keyword}/.match(text)
    return result[1] if result
  end
  return nil
end

def get_doc_description(doc)
  description = doc.css('.topic .body').first.content
  return description.gsub("\n", ' ')
end

