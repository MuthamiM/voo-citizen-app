// Supabase Connection for Dashboard
// Add this to your Render dashboard backend

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://xzhmdxtzpuxycvsatjoe.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Get from Supabase Dashboard > Settings > API

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// ============ EXAMPLE USAGE ============

// Get all issues from mobile app
async function getAllIssues() {
    const { data, error } = await supabase
        .from('issues')
        .select('*')
        .order('created_at', { ascending: false });
    return data;
}

// Update issue status (from dashboard)
async function updateIssueStatus(issueId, status, note) {
    // Update issue
    await supabase
        .from('issues')
        .update({ status: status, updated_at: new Date().toISOString() })
        .eq('id', issueId);

    // Add timeline entry
    await supabase
        .from('issue_timeline')
        .insert({
            issue_id: issueId,
            status: status,
            note: note,
            updated_by: 'Admin',
        });
}

// Get all app users
async function getAppUsers() {
    const { data, error } = await supabase
        .from('app_users')
        .select('id, full_name, phone, village, issues_reported, created_at')
        .order('created_at', { ascending: false });
    return data;
}

// Create announcement (from dashboard)
async function createAnnouncement(title, content, priority = 'normal') {
    const { data, error } = await supabase
        .from('announcements')
        .insert({
            title: title,
            content: content,
            priority: priority,
            created_by: 'Admin',
            is_active: true,
        })
        .select()
        .single();
    return data;
}

// Get bursary applications
async function getBursaryApplications() {
    const { data, error } = await supabase
        .from('bursary_applications')
        .select(`
      *,
      app_users (full_name, phone)
    `)
        .order('created_at', { ascending: false });
    return data;
}

// Approve/Reject bursary application
async function updateBursaryStatus(applicationId, status, amountApproved, notes) {
    await supabase
        .from('bursary_applications')
        .update({
            status: status,
            amount_approved: amountApproved,
            admin_notes: notes,
            updated_at: new Date().toISOString(),
        })
        .eq('id', applicationId);
}

module.exports = {
    supabase,
    getAllIssues,
    updateIssueStatus,
    getAppUsers,
    createAnnouncement,
    getBursaryApplications,
    updateBursaryStatus,
};
