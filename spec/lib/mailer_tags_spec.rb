require File.dirname(__FILE__) + "/../spec_helper"

describe "MailerTags" do
  dataset :mailer_page
  describe "<r:mailer>" do
    it "should render an error if the configuration is invalid" do
       pages(:home).should render("<r:mailer>true</r:mailer>").as("Mailer config is invalid: 'from' is required and 'recipients' is required")
     end

    it "should render its contents if the configuration is valid" do
      pages(:mail_form).should render("<r:mailer>true</r:mailer>").as('true')
    end
  end

  describe "<r:mailer:if_error>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'body' => 'Hello, world!')
    end

    it "should render its contents if there was an error in the last posted mail" do
      @mail.should_receive(:valid?).and_return(false)
      @page.should render('<r:mailer:if_error>Oops.</r:mailer:if_error>').as('Oops.')
    end

    it "should not render its contents if the last posted mail was valid" do
      @mail.should_receive(:valid?).and_return(true)
      @page.should render('<r:mailer:if_error>Oops.</r:mailer:if_error>').as('')
    end

    describe "when a field is specified" do
      it "should render its contents if there was an error on the specified field in the last posted mail" do
        @mail.errors['email'] = "is not a valid email"
        @page.should render('<r:mailer:if_error on="email">true</r:mailer:if_error>').as('true')
      end

      it "should not render its contents if there wasn't an error on the specified field in the last posted mail" do
        @mail.errors['email'] = "is not a valid email"
        @page.should render('<r:mailer:if_error on="name">true</r:mailer:if_error>').as('')
      end
    end
  end

  describe "<r:mailer:if_error:message>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'body' => 'Hello, world!')
    end

    it "should render the error message on the specified attribute" do
      @mail.errors['email'] = 'is not a valid email'
      @page.should render('<r:mailer:if_error on="email"><r:message /></r:mailer:if_error>').as("is not a valid email")
    end
  end

  describe "<r:mailer:unless_error>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'body' => 'Hello, world!')
    end

    it "should render its contents if there was not error in the last posted mail" do
      @mail.should_receive(:valid?).and_return(true)
      @page.should render('<r:mailer:unless_error>Oops.</r:mailer:unless_error>').as('Oops.')
    end

    it "should render its contents if the last posted mail was valid" do
      @mail.should_receive(:valid?).and_return(false)
      @page.should render('<r:mailer:unless_error>Oops.</r:mailer:unless_error>').as('')
    end

    describe "when a field is specified" do
      it "should not render its contents if there was an error on the specified field in the last posted mail" do
        @mail.errors['email'] = "is not a valid email"
        @page.should render('<r:mailer:unless_error on="email">true</r:mailer:unless_error>').as('')
      end

      it "should render its contents if there wasn't an error on the specified field in the last posted mail" do
        @mail.errors['email'] = "is not a valid email"
        @page.should render('<r:mailer:unless_error on="name">true</r:mailer:unless_error>').as('true')
      end
    end
  end

  describe "<r:mailer:form>" do
    it "should render a form that posts back to the page when mailer.post_to_page? is true" do
      Radiant::Config['mailer.post_to_page?'] = true
      pages(:mail_form).should render('<r:mailer:form />').as(
        %(<form action="/mail-form/" method="post" enctype="multipart/form-data" id="mailer"></form>
<script type="text/javascript">
  function showSubmitPlaceholder()
  {
    var submitplaceholder = document.getElementById("submit-placeholder-part");
    if (submitplaceholder != null)
    {
      submitplaceholder.style.display="";
    }
  }
</script>))
    end

    it "should render a form that posts back to the controller when mailer.post_to_page? is false" do
      Radiant::Config['mailer.post_to_page?'] = false
      pages(:mail_form).should render('<r:mailer:form />').as(
        %(<form action="/pages/#{page_id(:mail_form)}/mail#mailer" method="post" enctype="multipart/form-data" id="mailer"></form>
<script type="text/javascript">
  function showSubmitPlaceholder()
  {
    var submitplaceholder = document.getElementById("submit-placeholder-part");
    if (submitplaceholder != null)
    {
      submitplaceholder.style.display="";
    }
  }
</script>))
    end

    it "should render permitted passed attributes as attributes of the form tag" do
      pages(:mail_form).should render('<r:mailer:form class="foo" />').matching(/class="foo"/)
    end
  end

  describe "<r:mailer:if_success>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'body' => 'Hello, world!')
    end

    it "should render its contents if the last posted mail was sent successfully" do
      @mail.should_receive(:sent?).and_return(true)
      @page.should render('<r:mailer:if_success>true</r:mailer:if_success>').as('true')
    end

    it "should not render its contents if the last posted mail was not sent successfully" do
      @mail.should_receive(:sent?).and_return(false)
      @page.should render('<r:mailer:if_success>true</r:mailer:if_success>').as('')
    end
  end

  %w(text checkbox radio hidden).each do |type|
    describe "<r:mailer:#{type}>" do
      it "should render an input tag with the type #{type}" do
        pages(:mail_form).should render("<r:mailer:#{type} name='foo' />").as(%Q{<input type="#{type}" value="" id="foo" name="mailer[foo]" />})
      end

      it "should render permitted passed attributes as attributes of the input tag" do
        pages(:mail_form).should render("<r:mailer:#{type} name='foo' class='bar'/>").as(%Q{<input type="#{type}" value="" class="bar" id="foo" name="mailer[foo]" />})
      end

      it "should render the specified value as the value attribute" do
        pages(:mail_form).should render("<r:mailer:#{type} name='foo' value='bar'/>").as(%Q{<input type="#{type}" value="bar" id="foo" name="mailer[foo]" />})
      end

      it "should render the previously posted value when present as the value attribute, overriding a passed value attribute" do
        @page = pages(:mail_form)
        @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo' => 'Hello, world!')
        @page.should render("<r:mailer:#{type} name='foo' value='bar'/>").as(%Q{<input type="#{type}" value="Hello, world!" id="foo" name="mailer[foo]" />})
      end

      it "should add a 'required' hidden field when the required attribute is specified" do
        pages(:mail_form).should render("<r:mailer:#{type} name='foo' required='true'/>").as(%Q{<input type="#{type}" value="" id="foo" name="mailer[foo]" /><input type="hidden" name="mailer[required][foo]" value="true" />})
      end

      it "should raise an error if the name attribute is not specified" do
        pages(:mail_form).should render("<r:mailer:#{type} />").with_error("`mailer:#{type}' tag requires a `name' attribute")
      end
    end
  end

  describe "<r:mailer:submit>" do
    it "should render an input tag with the type submit" do
      pages(:mail_form).should render("<r:mailer:submit name='foo' />").as(
        %Q{<input onclick="showSubmitPlaceholder();" type="submit" value="foo" id="mailer-form-button" name="mailer[mailer-form-button]" />})
    end

    it "should render an input tag with the type image if src supplied" do
      pages(:mail_form).should render("<r:mailer:submit src='/img.jpg' value='foo' />").as(
        %Q{<input onclick="showSubmitPlaceholder();" type="image" src="/img.jpg" value="foo" id="mailer-form-button" name="mailer[mailer-form-button]" />})
    end

    it "should render permitted passed attributes as attributes of the input tag" do
      pages(:mail_form).should render("<r:mailer:submit name='foo' class='bar'/>").as(
        %Q{<input onclick="showSubmitPlaceholder();" type="submit" value="foo" class="bar" id="mailer-form-button" name="mailer[mailer-form-button]" />})
    end

    it "should render the specified value as the value attribute" do
      pages(:mail_form).should render("<r:mailer:submit name='foo' value='bar'/>").as(
        %Q{<input onclick="showSubmitPlaceholder();" type="submit" value="bar" id="mailer-form-button" name="mailer[mailer-form-button]" />})
    end

    it "should not raise an error if the name attribute is not specified" do
      pages(:mail_form).should render("<r:mailer:submit />").as(
        %Q{<input onclick="showSubmitPlaceholder();" type="submit" value="" id="mailer-form-button" name="mailer[mailer-form-button]" />})
    end
  end
  
  describe "<r:mailer:submit_placeholder>" do
    it "should render an placeholder div if submit_placeholder esists" do
      pages(:mail_form).should render("<r:mailer:submit_placeholder />").as(
        %Q{<div id="submit-placeholder-part" style="display:none">sending email...</div>})
    end
    it "should render nothing if submit_placeholder doesn't esist" do
      pages(:plain_mail).should render("<r:mailer:submit_placeholder />").as("")
    end
  end

  describe "<r:mailer:select>" do
    it "should render a select tag" do
      pages(:mail_form).should render('<r:mailer:select name="foo" />').as('<select size="1" id="foo" name="mailer[foo]"></select>')
    end

    it "should raise an error if the name attribute is not specified" do
      pages(:mail_form).should render("<r:mailer:select />").with_error("`mailer:select' tag requires a `name' attribute")
    end

    it "should render its contents within the select tag" do
      pages(:mail_form).should render('<r:mailer:select name="foo">bar</r:mailer:select>').as('<select size="1" id="foo" name="mailer[foo]">bar</select>')
    end

    it "should render nested <r:mailer:option> tags as option tags" do
      pages(:mail_form).should render('<r:mailer:select name="foo"><r:option value="bar">bar</r:option></r:mailer:select>').as('<select size="1" id="foo" name="mailer[foo]"><option value="bar" >bar</option></select>')
    end

    it "should select the specified option tag on a new form" do
      pages(:mail_form).should render('<r:mailer:select name="foo"><r:option value="bar" selected="selected">bar</r:option><r:option value="baz">baz</r:option></r:mailer:select>').as('<select size="1" id="foo" name="mailer[foo]"><option value="bar" selected="selected" >bar</option><option value="baz" >baz</option></select>')
    end

    it "should select the option tag with previously posted value" do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo' => 'baz')
      @page.should render('<r:mailer:select name="foo"><r:option value="bar" selected="selected">bar</r:option><r:option value="baz">baz</r:option></r:mailer:select>').as('<select size="1" id="foo" name="mailer[foo]"><option value="bar" >bar</option><option value="baz" selected="selected" >baz</option></select>')
    end
    
    it "should add a 'required' hidden field when the required attribute is specified" do
      pages(:mail_form).should render("<r:mailer:select name='foo' required='true'/>").as(%Q{<select size="1" id="foo" name="mailer[foo]"></select><input type="hidden" name="mailer[required][foo]" value="true" />})
    end
  end
  
  describe "<r:mailer:date_select>" do    
    # HACK: Quick way to get a tag rendered to string in the context of a page.
    # How can this be made better?
    def render_tag_in_mailer(content)
      tag = Spec::Rails::Matchers::RenderTags.new
      tag.send(:render_content_with_page, content, pages(:mail_form))
    end    
    
    it "should render select tags for each date component" do
      date_select = render_tag_in_mailer('<r:mailer:date_select name="foo" />')
      date_select.should have_tag('select[name=?]', "mailer[foo(1i)]")
      date_select.should have_tag('select[name=?]', "mailer[foo(2i)]")
      date_select.should have_tag('select[name=?]', "mailer[foo(3i)]")
    end
    
    it "should include blank options" do
      date_select = render_tag_in_mailer('<r:mailer:date_select name="foo" include_blank="true" />')
      date_select.should have_tag('select[name=?]', "mailer[foo(1i)]") do
        with_tag('option[value=?]', '')
      end
      date_select.should have_tag('select[name=?]', "mailer[foo(2i)]") do
        with_tag('option[value=?]', '')
      end
      date_select.should have_tag('select[name=?]', "mailer[foo(3i)]") do
        with_tag('option[value=?]', '')
      end
    end
    
    it "should order select tags" do
      date_select = render_tag_in_mailer('<r:mailer:date_select name="foo" order="day,year,month" />')
      date_select.should have_tag('select[name=?]+select[name=?]+select[name=?]','mailer[foo(3i)]', 'mailer[foo(1i)]', 'mailer[foo(2i)]')
    end
  end

  describe "<r:mailer:textarea>" do
    it "should render a textarea tag" do
      pages(:mail_form).should render('<r:mailer:textarea name="body" />').as('<textarea id="body" rows="5" cols="35" name="mailer[body]"></textarea>')
    end

    it "should raise an error if the name attribute is not specified" do
      pages(:mail_form).should render("<r:mailer:textarea />").with_error("`mailer:textarea' tag requires a `name' attribute")
    end

    it "should render its contents as the contents of the textarea tag" do
      pages(:mail_form).should render('<r:mailer:textarea name="body">Hello, world!</r:mailer:textarea>').as('<textarea id="body" rows="5" cols="35" name="mailer[body]">Hello, world!</textarea>')
    end
    
    it "should add a 'required' hidden field when the required attribute is specified" do
      pages(:mail_form).should render("<r:mailer:textarea name='body' required='true'/>").as(%Q{<textarea id="body" rows="5" cols="35" name="mailer[body]"></textarea><input type="hidden" name="mailer[required][body]" value="true" />})
    end
  end
  
  describe "<r:mailer:radiogroup>" do
    it "should render its contents" do
      pages(:mail_form).should render('<r:mailer:radiogroup name="foo">bar</r:mailer:radiogroup>').as('bar')
    end
    
    it "should concatenate the radiogroup's name with the option's value and save this as the option's id attribute" do
      pages(:mail_form).should render('<r:mailer:radiogroup name="foo"><r:option value="bar" selected="selected"/><r:option value="baz" /></r:mailer:radiogroup>').as('<input type="radio" value="bar" checked="checked" id="foobar" name="mailer[foo]" /><input type="radio" value="baz" id="foobaz" name="mailer[foo]" />')
    end
    
    it "should raise an error if the name attribute is not specified" do
      pages(:mail_form).should render("<r:mailer:radiogroup />").with_error("`mailer:radiogroup' tag requires a `name' attribute")
    end
    
    it "should render nested <r:mailer:option> tags as radio buttons" do
      pages(:mail_form).should render('<r:mailer:radiogroup name="foo"><r:option value="bar" /></r:mailer:radiogroup>').as('<input type="radio" value="bar" id="foobar" name="mailer[foo]" />')
    end
    
    it "should select the specified radio button on a new form" do
      pages(:mail_form).should render('<r:mailer:radiogroup name="foo"><r:option value="bar" selected="selected"/><r:option value="baz" /></r:mailer:radiogroup>').as('<input type="radio" value="bar" checked="checked" id="foobar" name="mailer[foo]" /><input type="radio" value="baz" id="foobaz" name="mailer[foo]" />')
    end
    
    it "should select the radio button with previously posted value" do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo' => 'baz')
      @page.should render('<r:mailer:radiogroup name="foo"><r:option value="bar" selected="selected"/><r:option value="baz" /></r:mailer:radiogroup>').as('<input type="radio" value="bar" id="foobar" name="mailer[foo]" /><input type="radio" value="baz" checked="checked" id="foobaz" name="mailer[foo]" />')
    end
  end
  
  describe "<r:mailer:get>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo' => 'baz')
    end
    
    it "should render the data as YAML when no name is given" do
      @page.should render('<r:mailer:get />').as("--- \nfoo: baz\n")
    end
    
    it "should render the specified datum" do
      @page.should render('<r:mailer:get name="foo" />').as('baz')
    end
    
    it "should render nothing when the value is not present" do
      @page.should render('<r:mailer:get name="body" />').as('')
    end
    
    it "should render date when date params are detected" do
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo(1i)' => '2008', 'foo(2i)' => '10', 'foo(3i)' => '29')
      @page.should render('<r:mailer:get name="foo" />').as('2008-10-29')
    end
  end
  
  describe "<r:mailer:get_each>" do
    before :each do
      # This simulates variables like :
      #   products[0][qty]=10
      #   products[0][name]=foo
      #   products[1][qty]=5
      #   products[1][name]=bar
      test_array=[ { 'qty' => 10, 'name' => 'foo' }, 
                   { 'qty' => 5, 'name' => 'bar' } ]
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'qty' => 'wrong', 'products' => test_array)
    end
    
    it "should not alter the content on its own" do
      @page.should render('<r:mailer:get_each />').as('')
    end
    
    it "should make mailer:get use the local variables" do
      # If this fails, it will show "wrongwrong" or something like that
      @page.should render('<r:mailer:get_each name="products"><r:mailer:get name="qty" /></r:mailer:get_each>').as('105')
    end
    
    it "should iterate and provide mailer:get the local variables" do
      @page.should render('<r:mailer:get_each name="products"><r:mailer:get name="qty" />x<r:mailer:get name="name" />,</r:mailer:get_each>').as('10xfoo,5xbar,')
    end
    
    it "should provide mailer:index" do
      @page.should render('<r:mailer:get_each name="products"><r:mailer:index /><r:mailer:get name="name" /></r:mailer:get_each>').as('0foo1bar')
    end

    describe 'if responds to original_filename' do
      it "should render it for single files" do
        file = mock(StringIO, :original_filename => "readme.txt")
        @page.last_mail = @mail = Mail.new(@page, config(@page), 'file' => file)
        @page.should render('<r:mailer:get name="file" />').as('readme.txt')
      end

      # It is valid to have 2 files on a single input name
      it "should render them as sentence for 2 files" do
        file = mock(StringIO, :original_filename => "readme.txt")
        file2 = mock(StringIO, :original_filename => "install.txt")
        @page.last_mail = @mail = Mail.new(@page, config(@page), 'file' => [file, file2])
        @page.should render('<r:mailer:get name="file" />').as('readme.txt and install.txt')
      end

      # It is valid to have multiple files on a single input name
      it "should render them as sentence for multiple files" do
        file = mock(StringIO, :original_filename => "readme.txt")
        file2 = mock(StringIO, :original_filename => "install.txt")
        file3 = mock(StringIO, :original_filename => "rakefile")
        @page.last_mail = @mail = Mail.new(@page, config(@page), 'file' => [file, file2, file3])
        @page.should render('<r:mailer:get name="file" />').as('readme.txt, install.txt, and rakefile')
      end
    end
  end
  
  describe "<r:mailer:if_value>" do
    before :each do
      @page = pages(:mail_form)
      @page.last_mail = @mail = Mail.new(@page, config(@page), 'foo' => 'baz')
    end
    
    it "should render its contained block if the specified value was submitted" do
      @page.should render('<r:mailer:if_value name="foo">true</r:mailer:if_value>').as('true')
    end

    it "should render not its contained block if the specified value was not submitted" do
      @page.should render('<r:mailer:if_value name="bar">true</r:mailer:if_value>').as('')
    end
  end
  
  
  private
  
  def config(page)
    string = page.render_part(:mailer)
    string.empty? ? {} : YAML::load(string).symbolize_keys
  end
end