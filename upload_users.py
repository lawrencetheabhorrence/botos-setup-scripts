from django.contrib.auth import get_user_model
import pandas as pd
import numpy as np
import core.models.user_models as um
import core.models.election_models as em

User = get_user_model()
df = pd.read_csv("userdata.csv",index_col=False)
rows = df.shape[0]

for i in range(rows):
    r = df.iloc[i]
    if not User.objects.filter(email=r['Email:']):
        User.objects.create_user(username=r['Username:'],
                         email=r['Email:'],
                         password=r['Password:'],
                         first_name=r['First Name:'],
                         last_name=r['Last Name:'])

# Now we create the VoterProfiles, but we have to instatiate some data first
sections = np.concatenate((df["Section:"].unique(),["A12","B12","C12"]))
batches = df["Batches:"].unique()
sy = "2022-2023" # change this to your liking
elec = em.Election(name=sy)
elec.save()

# we save sections and batches to the database
for s in sections:
    um.Section(section_name=s).save()
for b in batches:
    um.Batch(year=batches,election=elec).save()

# helper functions to retrieve the section and batch of a user
def c(v):
    return df["Email Address:"] == v.email
def get_batch(v):
    return df[c(v)]["Batch:"][0]
def get_section(v):
    # we have to do it this way probably due
    # to a quirk with how strings are represented
    # in pandas
    return df[c(v)]["Section:"].values[0]

# now we can attach VoterProfiles to each of the users
for v in um.User.objects.filter(is_staff=False):
    # check if data hasn't been added to the user
    if not um.VoterProfile.objects.filter(user=v):
        try:
            batch = get_batch(v)
        except Exception as e:
            print(e)
            print("Either the batch is missing or malformed. Try checking your userdata.csv file")
        else:
            try:
                section = get_section(v)
            except Exception as e:
                print(e)
                print("Either the section is missing or malformed. Try checking your userdata.csv file")
            else:
                vp = um.VoterProfile(user=v,
                                  has_voted=False,
                                  batch=batch,
                                  section=section)
                vp.save()
