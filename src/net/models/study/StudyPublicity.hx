package net.models.study;

enum abstract StudyPublicity(String) from String to String
{
	var PUBLIC = "public";
	var PROFILE_AND_LINK_ONLY = "profile_and_link_only";
	var LINK_ONLY = "link_only";
	var PRIVATE = "private";
}
