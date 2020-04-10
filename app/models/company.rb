class Company < ApplicationRecord
   require 'nokogiri'
   require 'open-uri'
   require "connect.rb"


    WIKIPEDIA_HOST = 'https://en.wikipedia.org'
    NTH_CHILD_NO = 1 #14
    NEG_KEYWORDS = ['defunct','acquired','inactive']
    KEYWORDS = {'website' => 'domain', 'industry'=>'industry_tags', 'number of employees'=>'no_of_employees', 
               'revenue' => 'revenue','headquarters'=> 'headquarters','key people'=>'key_people_blurb' }
    CRUNCH_KEYWORDS = {'Website' => 'domain', 'Categories'=>'industry_tags','Industries'=>'industry_tags', 'Number of Employees'=>'no_of_employees', 
                        'Last Funding Type' => 'funding_stage','Headquarters Regions'=> 'headquarters',
                        'Phone Number' => 'phone','Legal Name'=>'name', 'Contact Email'=> 'email','IPO Status'=>'ipo_status','Company Type'=>'company_type'
                      }    
    CRUNCH_LABELS = {"TotalFundingAmount" => 'funding_amount',"Acquiredby"=>'acquired_by'} 
    DESC2_XPATH = '//*[@id="section-overview"]/mat-card/div[2]/image-with-fields-card/image-with-text-card/div/div/div[2]/div[2]/field-formatter/span'                    

    has_many :key_people, :dependent => :destroy
    has_many :customer_associations, :foreign_key => :customer_id,
           :class_name => 'CustomerProspect'
    has_many :customers, :through => :customer_associations,
           :source => :prospect
    has_many :prospect_associations, :foreign_key => :prospect_id,
           :class_name => 'CustomerProspect'
    has_many :prospects, :through => :prospect_associations,
           :source => :customer

    #validates :domain, uniqueness: true

#To do
#add fields email_pattern email_pattern2 to company and sent_verification_email,email_bounced:default true to key people 
#scrape website and craft to get leadership
#scrape rocketreach and lusha for email pattern
#Before generating email check if first or last name has - or two names
#guess email format on the fly after a bounce

    def self.scrape_site url 
    begin
     document = URI.open(url)
     html = document.read
     Nokogiri::HTML(html)
     #doc.xpath('//*[@id="mw-pages"]/div/div/div[2]/ul').children.map(&:children).map{|obj| obj.first}.map{|ob|ob.attributes if ob}.map{|o|o['href'].value if o}.compact
    rescue => e 
      puts "#{url} could not open  #{e.message}"
         #notify airbrake
    end
  end

  def self.wikipedia_scrape url
      doc = scrape_site(url)
      #delay for some time
      puts ">>>about to sleep"
      sleep(rand(10..20))
        paths = doc.css("div.mw-category-group ul li a").map{|obj| obj.attributes['href'].value}
        paths[1..2].each { |path| 
            company_params = {}
            key_people = nil
            founders = nil
            company_doc = scrape_site("https://en.wikipedia.org#{path}")
            large_description = company_doc.css("#mw-content-text > div > p").text[0..20000]
            table = company_doc.css("#mw-content-text > div > table.infobox.vcard > tbody")
            if table.present?
              t_rows = table.children.map{|tr| [tr.children[0].text,tr.children[1].text] if tr.children[0].present? && tr.children[1].present?}.compact
              keys = t_rows.map{|sub| sub[0]}.map(&:downcase)
              values = t_rows.map{|sub| sub[1]}.map(&:downcase)
               if !skip_save?(keys,values)
                  keys.each_with_index do |key,i|
                    KEYWORDS.each do |keyword, column|
                      if String::Similarity.cosine(keyword, key) > 0.90
                        puts "detected #{key} from #{keyword}"
                        company_params[column.to_sym]= (key == 'website')? values[i].split("www.").last : values[i]
                      elsif String::Similarity.cosine(keyword, key) < 0.90 && String::Similarity.cosine(keyword, key) > 0.75
                        puts ">>>>This is a possibility #{key} from #{keyword}"
                      end
                    end
                  end
                  company = Company.new(company_params)
                  company.source = 'wikipedia'
                  company.save!
                  puts ">>>>>>path>>>>#{path}  keys #{keys} and values #{values}"
                end  
            else
              #record the company that dont have tables
              puts ">>>>>No table for >>>>>#{path}"
            end
            #delay for some time
            puts ">>>about to sleep"
            sleep(rand(10..20))
        }
      

  end

  def self.get_crunchbase_link query
      response = google_search("#{query}  www.crunchbase.com")
      item = response['items'].detect{|item| item['displayLink'] == "www.crunchbase.com"}
      item['link']
  end

  def get_company_email_format
     return if self.email_pattern1.present?
     
     email_format = nil
     if self.acquired_by.present?
       parent_org = Company.find_by_source_url('https://www.crunchbase.com' + self.acquired_by)
       if parent_org
         company_domain = parent_org.domain
         parent_org_email_format = Company.get_email_format(company_domain)
         parent_org.update(email_pattern1: parent_org_email_format) if parent_org_email_format != 'could_not_predict'
         email_format = parent_org_email_format 
       end
     end
     email_format = Company.get_email_format self.domain if email_format.nil?
     if email_format != 'could_not_predict'
        self.update(email_pattern1: email_format)
     end
  end

  def self.get_email_format_link query
      response = google_search("#{query} email format")
      # puts ">>>>links #{response['items'].map{|o| o['displayLink']}} "
      item = response['items'].detect{|item| item['displayLink'] == "www.rocketreach.co" || item['displayLink']== "www.lusha.co"}
      puts ">>>>>link #{item}"
      item['link'] if item
  end

  def self.get_email_format query
     url = get_email_format_link(query)
     if url.present?
       page = Company.scrape_site url
        if url.include? "rocketreach"
          puts "through rocketreach"
         formats_page = page.children[1].children[1].children.map(&:attributes).map{|obj| obj['content'] if obj.present? && obj['content']}.compact
         formats = formats_page.select{|obj|obj.value.include?('email format') && obj.value.include?('@')}
          if formats[0].text.include?("first_initial last@")
            'FI.lastname'
          elsif formats[0].text.include?("first '.' last@")
            'first.last'
          elsif formats[0].text.include?("first@")
            'first'
          else
            puts ">>>>>>>>>it didnt match any email format"
            'first.last'
          end
        elsif url.include? 'lusha'  
            puts "through lusha"
          format_page = page.css('body > div.main-content > section.wrapper.grey.formats-table-section > div > div > div')
           if format_page.text.include?("first '.' last")
             'first.last'
           elsif format_page.text.include?("first_initial last")
             'FI.lastname'
           elsif format_page.text.include?("first")
            'first'
           end
        end
      else
        puts "No email format link, we gona use employee number"
        company = Company.find_by_domain query
        if company.no_of_employees
          if  company.no_of_employees > 0 && company.no_of_employees/2 < 300
              'first'
          elsif company.no_of_employees > 0
             'FI.lastname'
          else
             'could_not_predict'
          end
        elsif company.ipo_status == 'Public'
            'first.last'
        else
          puts "No number of employees, we gona guess"
           'FI.lastname'
        end
      end
  end

  def self.google_search query
     request = Connect::Request.new(GOOGLE_HOST,GOOGLE_SEARCH_PATH, GOOGLE_CSE_KEY,{:cx=> CX,:q=> query})
     request.get
  end

  def self.scrape_with_proxy url
    puts SCRAPER_KEY
    request = Connect::Request.new(SCRAPER_HOST,nil, nil,{:url=> url,:api_key=> SCRAPER_KEY})
    request.get_html
  end

  def self.crunchbase_scrape query
    #To do 
    #medallia serves traditional markets
    acq =[]
    current_team = nil
    url = query.include?('http')? query : get_crunchbase_link(query)
    #in the future we ll have to check if website/query exists?
    url = url.chop if url[-1] == '/'
    c = Company.find_by_source_url(url)
    if c.present? && c.domain.present?
       puts ">>>>>>>>>>>>The company is already in the database"
       #fill_up_the_rest(url)
     else
        doc = scrape_with_proxy(url) if url.present?
        delay
        
        sc=doc.xpath('//script[not(@src)]')
        employees = sc.text.split(",").map(&:downcase).uniq.select{|e|e.include?('@') && (e.include?('chief') || e.include?('director')|| e.include?('president')|| e.include?('manager'))}
       # section_content = nil
        if !doc.children[1].children[0].children[0].text.include?("Request failed")
           # section_content = doc.css('div.section-layout-content  fields-card div.layout-wrap')
           acquisitions = doc.css('section-layout').detect{|obj|obj.attributes["cbtableofcontentsitem"].value == 'Acquisitions' if obj.attributes["cbtableofcontentsitem"]}
           if acquisitions.present?
            puts ">>>>acquisitions through nokogiri"
            list_card = acquisitions.children[0].children[1].children.find{|item| item.name=='list-card' if item.present?}
            table = list_card.children[0].children.find{|it| it.name == 'table' if it.present?}.children.find{|it| it.name == 'tbody' if it.present?}
            acq = table.children.map{|item| item.first_element_child.child.child.child.attributes['href'].value}.compact
            acq = acq.map{|c| 'https://www.crunchbase.com' + c}
           else 
            acq_through_sc = sc.text.split(",").map(&:downcase).uniq.select{|e|e.include?('acquired by')}.compact.map{|c| 'https://www.crunchbase.com/organization/'+ c.split("acquired by")[0].split(";").last.strip.sub(/\./,'-')}.uniq
             puts ">>>>There are no acquisitions in Noko,  acquisitions through script is #{acq_through_sc}"
            #acq= sc.text.split(",").map(&:downcase).uniq.select{|e|e.include?('acquired by')}.compact.map{|c| 'https://www.crunchbase.com/organization/'+ c.split("acquired by")[0].split(";").last.strip.sub(/\./,'-')}.uniq
            #check if it is in script
           end
           current_team=doc.css('section-layout').detect{|obj|obj.attributes["cbtableofcontentsitem"].value == 'Current Team' if obj.attributes["cbtableofcontentsitem"]}
            keys=doc.css('div.section-layout-content  fields-card div.layout-wrap').children.map.each_with_index{|n,i|
              if i%2==0
               n.text.chop
              end
             }.compact

             values = doc.css('div.section-layout-content  fields-card div.layout-wrap').children.map.each_with_index{|n,i|
              if i%2!=0
               n.text.strip
              end
             }.compact
         
            if (keys.include?("Operating Status") && values[keys.index("Operating Status")] != 'Active' && values[keys.index("Operating Status")] != 'Acquired') || (current_team.blank? && !keys.include?('Website'))
              puts ">>>>>>> the company is NOT active, skipping"
              c.delete if c.present? 
            else
                 #check if revenue,acquisitions,competitors&revenue  exists
                 # also add acquisitions,compititors field,company_email
                 labels = doc.css('div.section-layout-content  mat-card.layout-row span.bigValueItemLabelOrData')
                 key_labels =labels.map.each_with_index{|l,i|l.text.gsub(/[[:space:]]/, '') if i%2==0}.compact
                 value_labels = labels.map.each_with_index{|l,i|l.text.gsub(/[[:space:]]/, '') if i%2!=0}.compact

                 raw_values = doc.css('div.section-layout-content  fields-card div.layout-wrap').children.map.each_with_index{|n,i|
                  if i%2!=0
                   n
                  end
                 }.compact

                 website = values[keys.index('Website')].strip if keys.include?('Website')
                 company = Company.find_by_domain(website) if website
                 params = {}
                 no_of_teams = 0
                 if company.present?
                  
                     puts ">>>>>>>This company already exists"

                 else
                   params = build_columns(keys,values, CRUNCH_KEYWORDS)
                   if c.present?
                     company = c
                     company.update(params)
                   else
                     company = Company.new(params)
                     company.source_url = (url[-1] == '/')? url.chop : url
                     puts ">>>>>>>about to saved company for the first time"
                   end
                    company.description = doc.css('div.section-layout-content description-card p').text
                    company.description2 = doc.xpath(DESC2_XPATH).text
                    #this might change
                    company.serves_traditional_market = false
                    company.source = 'crunchbase'
                    company.save!
                   if keys.include?('Founders') || key_labels.include?("NumberofCurrentTeamMembers")
                         founders = keys.index('Founders').present? ? values[keys.index('Founders')].strip.split(",") : []
                          founders.each do |full_name|
                            key_person = KeyPerson.new(:first_name=> full_name.split[0], :last_name=> full_name.split[1],:title=> 'Founder')
                            company.key_people << key_person
                          end
                        founders = company.key_people.map{|obj|obj.first_name + obj.last_name} || []
                        team=current_team.children[0].children[1].children.detect{|obj| obj.name == 'image-list-card'} if current_team.present?
                        if current_team.present?
                          team_members =team.children[0].children.map{|obj| obj.children[1].children }
                          team_members.each do |member|
                            first_name = member.children[0].text.strip.split[0]
                            last_name = member.children[0].text.strip.split[1].to_s
                            unless founders.include?(first_name+last_name)
                             team_member = KeyPerson.new(:first_name=> first_name,:last_name=>last_name.to_s,:title=>member.children[1].text.strip)
                             company.key_people << team_member
                             company.populated = true
                            end
                            puts ">>>>>>>We have team members through Nokogiri"
                          end
                        elsif employees.present? && employees.map{|a| a.split('@')[0].split("&q;value&q;:&q;")[1]}.compact.present?
                          employees = employees.map{|a| a.split('@')[0].split("&q;value&q;:&q;")[1]}.compact
                          employees.each{|p| 
                            team_member = KeyPerson.new(:first_name=> p.split[0].strip,:last_name=>p.split[1].strip,:title=>p.split[2..-1].join(" ").strip)
                             company.key_people << team_member
                          }
                           company.populated = true
                           puts ">>>>>>>We have team members through json script"
                        else
                          puts ">>>>>>>We have founders but NO team members"
                        end
                    else
                        puts ">>>>>>>NO Founders NO team members"
                    end

                    if key_labels.include?("Acquiredby")
                       vl = labels.map.each_with_index{|l,i|l if i%2!=0}.compact
                       acquirer = vl[key_labels.index("Acquiredby")].children[0].children[0].children[0].attributes['href'].value
                       company.acquired_by = acquirer
                        puts ">>>>>>>the company is acquired"
                    end

                    if key_labels.include?("TotalFundingAmount")
                        company.funding_amount = value_labels[key_labels.index("TotalFundingAmount")]
                    end

                    if keys.include?("LinkedIn")
                       company.linkedin_link = raw_values[keys.index('LinkedIn')].children[0].children[0].children[0].attributes['href'].value
                    end
                     company.save!
                     puts ">>>>>>>finished successfully"
                    if acq.present?
                        puts " >>>> acquistions #{acq}"
                        results = Company.insert_all(acq.map{|c|{source_url: c, created_at: Time.now,updated_at: Time.now}})
                        puts "after insert result #{results.inspect}"
                    end
                  end
              end 
          else
            puts "Request failed for url #{url}"
            puts "section_content >>>>>>#{doc.css('div.section-layout-content  fields-card div.layout-wrap')}"
          end 
       end      
  end

  def self.skip_save? keys,values
       return true if keys.include?('defunct') || keys.include?('parent') || (values & NEG_KEYWORDS).present?
  end

   def self.delay
      sleep(rand(20..30))
   end

   def self.build_columns keys,values, keywords
     company_params={}
     keys.each_with_index do |key,i|
          keywords.each do |keyword, column|
            if String::Similarity.cosine(keyword, key) > 0.90
              puts "detected #{key} from #{keyword}"
              if key == "Number of Employees" && values[i].include?("-")
                company_params[column.to_sym] = values[i].split("-").map(&:to_i).sum 
              elsif keyword == 'Website'
                 company_params[column.to_sym] = values[i].split("www.").last.delete('/')
              else
              company_params[column.to_sym]= values[i] 
            end
            elsif String::Similarity.cosine(keyword, key) < 0.90 && String::Similarity.cosine(keyword, key) > 0.75
              puts ">>>>This is a possibility #{key} from #{keyword}"
            end
          end
        end
    company_params
   end

def self.fill_up_the_rest url
  puts ">>>>>>>>>filling up the rest"
  doc = scrape_with_proxy(url)
    keys=doc.css('div.section-layout-content  fields-card div.layout-wrap').children.map.each_with_index{|n,i|
              if i%2==0
               n.text.chop
              end
             }.compact

             values = doc.css('div.section-layout-content  fields-card div.layout-wrap').children.map.each_with_index{|n,i|
              if i%2!=0
               n.text.strip
              end
             }.compact
#   acq =[]
#   doc = scrape_with_proxy(url)
#   sc=doc.xpath('//script[not(@src)]')
#     acquisitions = doc.css('section-layout').detect{|obj|obj.attributes["cbtableofcontentsitem"].value == 'Acquisitions' if obj.attributes["cbtableofcontentsitem"]}
#            if acquisitions.present?
#             puts ">>>>acquisitions through nokogiri"
#             acq =acquisitions.children[0].children[1].children.find{|item| item.name=='list-card' if item.present?}.children[0].children.find{|it| it.name == 'table' if it.present?}.children.find{|it| it.name == 'tbody' if it.present?}.children.map{|item| item.first_element_child.child.child.child.attributes['href'].va
# ue}.compact
#             acq = acq.map{|c| 'https://www.crunchbase.com' + c}
#            else 
#              puts ">>>>acquisitions through script"
#             acq= sc.text.split(",").map(&:downcase).uniq.select{|e|e.include?('acquired by')}.compact.map{|c| 'https://www.crunchbase.com/organization/'+ c.split("acquired by medallia")[0].split(";").last.strip.sub(/\./,'-')}.uniq
#             #check if it is in script
#            end
#             if acq.present?
#               puts " >>>> acquistions #{acq}"
#               results =Company.insert_all(acq.map{|c|{source_url: c, created_at: Time.now,updated_at: Time.now}})
#               puts "after insert result #{results}"
#             end
end
   
end
